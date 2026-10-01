--[[ =========================================================================
        c_create_character.lua — Vortex CREATE CHARACTER (Fix #40, MOD 3 part 2)

        1:1 UIKit port of the OLD CLIENT create-character window
        (backupm roleplay character_c_decompiled.lua, create_character
        300x630 right-side window with primary top/bottom accent bars):

          * Character name edit with live auto-capitalisation + hint label
          * Birthday dd / mm / yyyy edits (age is derived, server stores
            age+month+day exactly like before)
          * Birthplace edit, Language combobox (language-system backed)
          * Height / Weight scrollbars with live cm/kg labels
          * Heritage switch (White/Black) + Gender switch (Male/Female)
            both flip the preview ped skin list like the old client
          * Skin cycling with ARROW LEFT / ARROW RIGHT + directive hint
          * Character Story window (memo)
          * Create Character button with the old-client validation rules

        SERVER CONTRACT UNCHANGED (s_create_character.lua):
          sends    accounts:characters:new(name, desc, race, gender, skin,
                   height, weight, age, language, month, day, location)
          receives accounts:characters:new(statusID, subID)
                   1:x validation error / 2:1 name in use / 2:2 db fail /
                   3:id success -> client spawns via accounts:characters:spawn
========================================================================= ]]

local localPlayer = getLocalPlayer()
-- [Fix #52] same load-time UIKit call death as c_characters.lua (account
-- starts before UIKit in mtaserver.conf): the whole creation UI died at
-- load, so CREATE CHARACTER was a dead tab. Lazy resolution instead.
local eui = nil
local REF_SX, REF_SY = 1728, 972

local function ensureUIKit()
        if eui then return true end
        local ok, exportsTable = pcall(function() return exports.UIKit end)
        if ok and exportsTable then
                eui = exportsTable
                return true
        end
        return false
end
local UI = { window = {}, label = {}, edit = {}, button = {}, scrollbar = {}, switch = {}, combobox = {}, memo = {} }
local built = false
local creationOpen = false
local creationPending = false
local currentSelectedSkin = 1
local languageItems = {}
local languageSelected = 0

-- classic default spawn (the disabled spawn-picker used this one)
local DEFAULT_LOCATION = { 1813.46875, -1803.6298828125, 13.556628227234, 359.0744, 0, 0, "Fort Carson City Hall" }

local PRIMARY_HEX = "#ff375f"

-- ===========================================================================
-- skin arrays (c_main.lua globals; race 0 = Black, 1 = White)
-- ===========================================================================

local function currentSkinArray()
        local female = eui:uiSwitchGetSelected(UI.switch.Gender)
        local black = eui:uiSwitchGetSelected(UI.switch.Heritage)
        if female then
                return black and (blackFemales or { 9 }) or (whiteFemales or { 12 })
        end
        return black and (blackMales or { 7 }) or (whiteMales or { 23 })
end

local function applyPreviewModel()
        if not isElement(lobby.showPed) then return end
        local array = currentSkinArray()
        currentSelectedSkin = math.max(1, math.min(currentSelectedSkin, #array))
        setElementModel(lobby.showPed, array[currentSelectedSkin] or 0)
        -- [Fix #54] keep the preview facing the camera after model swaps
        if type(faceShowPedToCamera) == "function" then faceShowPedToCamera() end
end

local function changeSkin(diff)
        local array = currentSkinArray()
        currentSelectedSkin = currentSelectedSkin + (diff or 0)
        if currentSelectedSkin > #array then currentSelectedSkin = 1 end
        if currentSelectedSkin < 1 then currentSelectedSkin = #array end
        applyPreviewModel()
end

local function onSkinArrow(_, _, diff)
        changeSkin(diff)
end

local function bindSkinArrows(on)
        if on then
                bindKey("arrow_l", "down", onSkinArrow, -1)
                bindKey("arrow_r", "down", onSkinArrow, 1)
                showDirective("اضغط اليسار أو اليمين لتغيير مظهر الشخصية")
        else
                unbindKey("arrow_l", "down", onSkinArrow)
                unbindKey("arrow_r", "down", onSkinArrow)
                showDirective(false)
        end
end

-- ===========================================================================
-- UI build
-- ===========================================================================

local function buildUI()
        if built then return true end
        if not ensureUIKit() then return false end -- [Fix #52] UIKit not up yet
        local okRef, refW, refH = pcall(function() return eui:uiGetReferenceScreenSize() end)
        if okRef and tonumber(refW) and tonumber(refH) then
                REF_SX, REF_SY = tonumber(refW), tonumber(refH)
        end

        -- create character window (300x630, right side)
        UI.window.create_character = eui:uiCreateRectangle(REF_SX - 450, false, 300, 630, "bg_default", true, true, true, true)
        eui:uiSetVisible(UI.window.create_character, false)
        eui:uiCreateRectangle(75, 0, 150, 5, "primary", false, false, false, false, UI.window.create_character)
        eui:uiCreateRectangle(75, 625, 150, 5, "primary", false, false, false, false, UI.window.create_character)

        UI.edit.Name = eui:uiCreateEdit(20, 30, 260, 30, "", { en = "Character name", ar = "اسم الشخصية" }, _, UI.window.create_character)
        eui:uiCreateLabel(20, 70, 260, 50,
                "لا تستخدم أسماء غير واقعية أو أسماء\nمبنية على أشخاص أو شخصيات مشهورة.",
                tocolor(255, 255, 255, 160), "left", "top", UI.window.create_character)
        eui:uiCreateRectangle(0, 120, 300, 1, tocolor(255, 255, 255, 10), false, false, false, false, UI.window.create_character)

        UI.label.Birthday = eui:uiCreateLabel(20, 130, 260, 20, { en = "Your Character Birthday:", ar = "تاريخ الميلاد:" }, "primary", "left", "top", UI.window.create_character)
        UI.edit.Day = eui:uiCreateEdit(20, 160, 50, 20, "", { en = "dd", ar = "يوم" }, _, UI.window.create_character)
        UI.edit.Month = eui:uiCreateEdit(75, 160, 50, 20, "", { en = "mm", ar = "شهر" }, _, UI.window.create_character)
        UI.edit.Year = eui:uiCreateEdit(130, 160, 80, 20, "", { en = "yyyy", ar = "السنة" }, _, UI.window.create_character)

        UI.label.Birthplace = eui:uiCreateLabel(20, 200, 260, 20, { en = "Birthplace:", ar = "مكان الميلاد:" }, "primary", "left", "top", UI.window.create_character)
        UI.edit.Birthplace = eui:uiCreateEdit(20, 230, 260, 20, "", "EX: Los Santos, ...", _, UI.window.create_character)

        UI.label.Language = eui:uiCreateLabel(20, 270, 260, 20, { en = "Language:", ar = "اللغة:" }, "primary", "left", "top", UI.window.create_character)
        UI.combobox.Language = eui:uiCreateComboBox(20, 300, 260, 20, "Language", tocolor(255, 255, 255), UI.window.create_character)

        eui:uiCreateRectangle(0, 340, 300, 1, tocolor(255, 255, 255, 10), false, false, false, false, UI.window.create_character)

        UI.label.Height = eui:uiCreateLabel(20, 360, 260, 20, { en = "Height:", ar = "الطول:" }, "primary", "left", "top", UI.window.create_character)
        UI.scrollbar.Height = eui:uiCreateScrollBar(20, 385, 260, 10, tocolor(204, 199, 199), tocolor(56, 49, 49), true, UI.window.create_character)
        UI.label.Weight = eui:uiCreateLabel(20, 405, 260, 20, { en = "Weight:", ar = "الوزن:" }, "primary", "left", "top", UI.window.create_character)
        UI.scrollbar.Weight = eui:uiCreateScrollBar(20, 430, 260, 10, tocolor(204, 199, 199), tocolor(56, 49, 49), true, UI.window.create_character)

        UI.label.Heritage = eui:uiCreateLabel(20, 460, 260, 20, { en = "Heritage:", ar = "الأصل:" }, "primary", "left", "top", UI.window.create_character)
        UI.switch.Heritage = eui:uiCreateSwitch(135, 462, 40, 15, "", false, tocolor(120, 120, 120), UI.window.create_character)
        eui:uiCreateLabel(45, 462, 85, 20, { en = "White", ar = "أبيض" }, tocolor(255, 255, 255, 160), "center", "top", UI.window.create_character)
        eui:uiCreateLabel(180, 462, 85, 20, { en = "Black", ar = "أسود" }, tocolor(255, 255, 255, 160), "center", "top", UI.window.create_character)

        UI.label.Gender = eui:uiCreateLabel(20, 490, 260, 20, { en = "Gender:", ar = "الجنس:" }, "primary", "left", "top", UI.window.create_character)
        UI.switch.Gender = eui:uiCreateSwitch(135, 492, 40, 15, "", false, tocolor(120, 120, 120), UI.window.create_character)
        eui:uiCreateLabel(45, 492, 85, 20, { en = "Male", ar = "ذكر" }, tocolor(255, 255, 255, 160), "center", "top", UI.window.create_character)
        eui:uiCreateLabel(180, 492, 85, 20, { en = "Female", ar = "أنثى" }, tocolor(255, 255, 255, 160), "center", "top", UI.window.create_character)

        UI.button.Story = eui:uiCreateButton(20, 525, 260, 25, { en = "Character Story", ar = "قصة الشخصية" }, "primary", UI.window.create_character)

        UI.button.CreateCharacter = eui:uiCreateButton(15, 575, 270, 35, { en = "Create Character", ar = "صنع الشخصية" }, _, UI.window.create_character)

        -- story window
        UI.window.Story = eui:uiCreateRectangle((REF_SX - 500) / 2, (REF_SY - 360) / 2, 500, 360, tocolor(20, 20, 20, 230), true, true, true, true)
        eui:uiSetVisible(UI.window.Story, false)
        UI.label.StoryTitle = eui:uiCreateLabel(15, 10, 470, 30, { en = "Character Story", ar = "قصة الشخصية" }, tocolor(255, 255, 255, 255), "left", "top", UI.window.Story)
        eui:uiSetFont(UI.label.StoryTitle, "default-large")
        UI.memo.Story = eui:uiCreateMemo(10, 45, 480, 260, "", tocolor(5, 5, 5, 240), UI.window.Story)
        eui:uiSetProperty(UI.memo.Story, "TextColor", tocolor(255, 255, 255, 255))
        UI.button.CloseStory = eui:uiCreateButton(10, 320, 480, 30, { en = "Hide", ar = "إخفاء" }, tocolor(0, 0, 0, 255), UI.window.Story)

        -- languages
        languageItems = {}
        local ok, count = pcall(function() return exports["language-system"]:getLanguageCount() end)
        if ok and tonumber(count) and tonumber(count) > 0 then
                for i = 1, tonumber(count) do
                        local okName, name = pcall(function() return exports["language-system"]:getLanguageName(i) end)
                        languageItems[i] = (okName and tostring(name)) or ("Language " .. i)
                end
        else
                languageItems = { "English", "Arabic" }
        end
        for _, lang in ipairs(languageItems) do
                eui:uiComboBoxAddItem(UI.combobox.Language, lang)
        end

        -- [Fix #52] built flips true only AFTER the whole build succeeds
        -- (a mid-build error must leave it false so the next open rebuilds)
        built = true
        return true
end

-- ===========================================================================
-- scrollbars -> live labels (server limits: height 150..200, weight 50..199)
-- ===========================================================================

addEventHandler("onClientUIScroll", root, function(scrollPos)
        if source == UI.scrollbar.Height then
                local h = 150 + math.floor((tonumber(scrollPos) or 0) / 2)
                eui:uiSetText(UI.label.Height, "الطول: " .. h .. " سم")
        elseif source == UI.scrollbar.Weight then
                local w = 50 + math.floor((tonumber(scrollPos) or 0) * 1.49)
                eui:uiSetText(UI.label.Weight, "الوزن: " .. w .. " كجم")
        end
end)

-- switches flip the preview skin list (old-client behaviour)
local clickCreate -- forward declaration (handler below fires it)
addEventHandler("onClientUIClick", root, function()
        if not creationOpen then return end
        if source == UI.switch.Heritage or source == UI.switch.Gender then
                currentSelectedSkin = 1
                applyPreviewModel()
        elseif source == UI.button.Story then
                eui:uiSetVisible(UI.window.Story, not eui:uiGetVisible(UI.window.Story))
        elseif source == UI.button.CloseStory then
                eui:uiSetVisible(UI.window.Story, false)
        elseif source == UI.button.CreateCharacter then
                clickCreate()
        end
end)

-- live auto-capitalisation of the name (old-client rule)
addEventHandler("onClientUIChanged", root, function()
        if source ~= UI.edit.Name then return end
        local text = eui:uiGetText(UI.edit.Name)
        if text == "" then return end
        text = text:gsub("_", " "):gsub("%s+", " "):gsub("(%a)([%w']*)", function(first, rest)
                return first:upper() .. rest:lower()
        end)
        eui:uiSetText(UI.edit.Name, text)
end)

-- ===========================================================================
-- open / close (called by the lobby tab system)
-- ===========================================================================

function lobbyCreation(state)
        -- [Fix #52] a failed/deferred buildUI must not crash the tab switch
        if not built then
                local okBuild, buildErr = pcall(buildUI)
                if not built then
                        if not okBuild then
                                outputChatBox("[Characters] Create UI build failed: " .. tostring(buildErr), 255, 100, 100, false)
                        end
                        return
                end
        end
        creationOpen = state
        if state then
                eui:uiSetText(UI.edit.Name, "")
                eui:uiSetText(UI.edit.Day, "")
                eui:uiSetText(UI.edit.Month, "")
                eui:uiSetText(UI.edit.Year, "")
                eui:uiSetText(UI.edit.Birthplace, "")
                eui:uiSetText(UI.memo.Story, "")
                eui:uiScrollBarSetScrollPosition(UI.scrollbar.Height, 0)
                eui:uiScrollBarSetScrollPosition(UI.scrollbar.Weight, 0)
                eui:uiSetText(UI.label.Height, "الطول: 150 سم")
                eui:uiSetText(UI.label.Weight, "الوزن: 50 كجم")
                eui:uiComboBoxSetSelected(UI.combobox.Language, -1)
                currentSelectedSkin = 1
                languageSelected = 0
                creationPending = false

                if not isElement(lobby.showPed) then
                        local spot = (lobby.cam and lobby.cam.spot) or { 706.1298, -1690.823, 3.4375, 180 }
                        lobby.showPed = createPed(0, spot[1], spot[2], spot[3])
                        setElementDimension(lobby.showPed, 65499)
                        setElementInterior(lobby.showPed, 0)
                        setPedRotation(lobby.showPed, spot[4])
                        local anim = getRandomAnim(2)
                        if anim then setPedAnimation(lobby.showPed, anim[1], anim[2], -1, true, false, false, false) end
                        -- [Fix #54] face the camera, not the spot's raw rotation
                        if type(faceShowPedToCamera) == "function" then faceShowPedToCamera() end
                end
                applyPreviewModel()

                eui:uiSetVisible(UI.window.create_character, true)
                bindSkinArrows(true)
        else
                eui:uiSetVisible(UI.window.create_character, false)
                eui:uiSetVisible(UI.window.Story, false)
                bindSkinArrows(false)
                -- restore the selected character on the preview ped
                local char = lobby.currentCharacters[lobby.selectedCharacter]
                if isElement(lobby.showPed) and char then
                        setElementModel(lobby.showPed, tonumber(char[9]) or 0)
                        local anim = getRandomAnim(tonumber(char[3]) == 1 and 4 or 2)
                        if anim then setPedAnimation(lobby.showPed, anim[1], anim[2], -1, true, false, false, false) end
                        -- [Fix #54] keep facing the camera after the model swap
                        if type(faceShowPedToCamera) == "function" then faceShowPedToCamera() end
                end
        end
end

-- harness/external introspection: is the create window currently open?
function isCreationOpen() return creationOpen end

-- legacy entry point (c_login.lua empty-list flow) - the lobby auto-opens
-- the create tab when the list is empty, so just make sure the lobby shows.
function newCharacter_init()
        if not lobby.selection_status then
                Characters_showSelection()
        end
end

-- ===========================================================================
-- validation + submit (old-client rules, Arabic feedback)
-- ===========================================================================

local function checkBirthDate(day, month, year)
        local d, m, y = tonumber(day), tonumber(month), tonumber(year)
        if not d or not m or not y then return false end
        if #tostring(day) < 1 or #tostring(month) < 1 or #tostring(year) ~= 4 then return false end
        if d < 1 or d > 31 then return false end
        if m < 1 or m > 12 then return false end
        if y < 1920 then return false end
        local age = os.date("*t").year - y
        if age < 16 or age > 100 then return false end
        return true, d, m, y
end

function clickCreate()
        if creationPending then
                lobbyToast("انتظر من فضلك", "info")
                return
        end

        local name = eui:uiGetText(UI.edit.Name)
        if utfLen(name) == 0 then
                lobbyToast("ادخل اسم الشخصية", "error") return
        end
        if utfSub(name, 1, 1) == " " then
                lobbyToast("يوجد مسافة في بداية اسم الشخصية", "error") return
        end
        if utfSub(name, utfLen(name), utfLen(name)) == " " then
                lobbyToast("يوجد مسافة في نهاية اسم الشخصية", "error") return
        end
        if string.match(name, "%d+") then
                lobbyToast("يجب ألا يحتوي اسم الشخصية على أرقام", "error") return
        end
        if not string.match(name, "^[+-]?%a+%s[%a+'?.?]+%a$") then
                lobbyToast("اسم الشخصية غير صالح (الاسم الأول الاسم الثاني)", "error") return
        end

        local okDate, d, m, y = checkBirthDate(eui:uiGetText(UI.edit.Day), eui:uiGetText(UI.edit.Month), eui:uiGetText(UI.edit.Year))
        if not okDate then
                lobbyToast("خطأ في تاريخ الميلاد (يجب أن يكون العمر 16-100)", "error") return
        end

        local birthplace = eui:uiGetText(UI.edit.Birthplace)
        if birthplace == "" then
                lobbyToast("اكتب مكان الميلاد", "error") return
        end

        local langIndex = eui:uiComboBoxGetSelected(UI.combobox.Language)
        if langIndex == -1 then
                lobbyToast("الرجاء اختيار اللغة", "error") return
        end
        languageSelected = langIndex + 1

        local gender = eui:uiSwitchGetSelected(UI.switch.Gender) and 1 or 0
        local race = eui:uiSwitchGetSelected(UI.switch.Heritage) and 0 or 1
        local skin = isElement(lobby.showPed) and getElementModel(lobby.showPed) or 0
        local height = 150 + math.floor(eui:uiScrollBarGetScrollPosition(UI.scrollbar.Height) / 2)
        local weight = 50 + math.floor(eui:uiScrollBarGetScrollPosition(UI.scrollbar.Weight) * 1.49)
        local age = os.date("*t").year - y
        local story = eui:uiGetText(UI.memo.Story)

        creationPending = true
        triggerServerEvent("accounts:characters:new", localPlayer,
                name, story, race, gender, skin, height, weight, age, languageSelected, m, d, DEFAULT_LOCATION)
end

-- ===========================================================================
-- server response (contract unchanged)
-- ===========================================================================

addEvent("accounts:characters:new", true)
addEventHandler("accounts:characters:new", root, function(statusID, statusSubID)
        creationPending = false
        if statusID == 3 then
                lobbyToast("تم إنشاء الشخصية بنجاح", "success")
                lobbyCreation(false)
                lobbyHide()
                fadeCamera(false, 1, 0, 0, 0)
                setTimer(function()
                        triggerServerEvent("accounts:characters:spawn", localPlayer, statusSubID)
                        triggerServerEvent("updateCharacters", localPlayer)
                end, 900, 1)
                return
        elseif statusID == 2 then
                if statusSubID == 1 then
                        lobbyToast("اسم الشخصية مستخدم بالفعل، عذرًا!", "error")
                else
                        lobbyToast("فشل إنشاء الشخصية، حاول مجددًا (رمز " .. tostring(statusSubID) .. ")", "error")
                end
        else
                lobbyToast("خطأ في البيانات المُرسلة (رمز " .. tostring(statusSubID) .. ")", "error")
        end
end)
