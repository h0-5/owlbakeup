--[[ =========================================================================
        login-panel/client.lua — Vortex LOGIN (Fix #39, MOD 3 part 1)

        1:1 UIKit port of the OLD CLIENT login (backupm roleplay/login):
          * midnight camera fly-in on random matrices + dark (0,3,8) backdrop
          * looped login music with fade-out (menu.mp3)
          * 350x500 panel (6,9,14,250) with primary top/bottom accent bars and a
            305x410 inner container, logo 100x100 alpha 180
          * LOGIN container: title, username/password edits with white icons on
            (19,22,27) pill rectangles, "Forgot password ?", remember-me switch,
            primary Login button (HoverGlow), "I do not have an account" switcher
          * REGISTER container: the one-account notice, username / password /
            confirm / email pills, primary Register button, left-arrow back
          * rememberme.xml persistence (server-issued saveLoginToXML/resetSaveXML)
          * Mode screen: when the server marks itself closed (resourceRoot
            elementData "Mode") the login is replaced by the mode message

        SERVER CONTRACT UNCHANGED (login-panel/server.lua):
          sends    onJoin, accounts:login:attempt(user, pass, save),
                   accounts:register:attempt(user, pass, confirm, email)
          receives beginLogin, set_warning_text, set_authen_text,
                   saveLoginToXML, resetSaveXML, hideLoginPanel, hideLoginWindow,
                   accounts:register:complete
========================================================================= ]]

local sx, sy = guiGetScreenSize()
local localPlayer = getLocalPlayer()

-- [Fix #45] `local eui = exports.UIKit` at load time raised
-- "exports: Call to non-running server resource (UIKit)" whenever the account
-- resource's client script started before UIKit did, which killed this script
-- (no beginLogin handler -> no login panel at all). Resolve it lazily instead.
local eui = nil

local function ensureUIKit()
        if eui then return true end
        local ok, exportsTable = pcall(function() return exports.UIKit end)
        if ok and exportsTable then
                eui = exportsTable
                return true
        end
        return false
end

local music = nil
local fadeout_sound_timer = nil
local visible = false
local built = false
local UI = { window = {}, label = {}, edit = {}, button = {}, rect = {}, image = {}, checkbox = {}, container = {} }

-- rememberme persistence ---------------------------------------------------
-- [Fix #44] childFor: the shipped rememberme.xml has an EMPTY root (no
-- <username>/<password> children), so the old xmlFindChild-then-set path
-- silently wrote nothing on the live server and the panel never pre-filled
-- again (found by the live-server hotfix round). Create the child when it
-- is missing.
local REMEMBER_FILE = "login-panel/rememberme.xml"

local function childFor(xml, name)
        local node = xmlFindChild(xml, name, 0)
        if not node then
                node = xmlCreateChild(xml, name)
        end
        return node
end

local function saveRemember(username, password)
        local xml = xmlLoadFile(REMEMBER_FILE)
        if not xml then
                xml = xmlCreateFile(REMEMBER_FILE, "login")
                if not xml then return false end
        end
        local un = childFor(xml, "username")
        local pw = childFor(xml, "password")
        if un then xmlNodeSetValue(un, tostring(username or "")) end
        if pw then xmlNodeSetValue(pw, tostring(password or "")) end
        xmlSaveFile(xml)
        xmlUnloadFile(xml)
        return true
end

local function clearRemember()
        saveRemember("", "")
end

local function loadRemember()
        local xml = xmlLoadFile(REMEMBER_FILE)
        if not xml then return "", "" end
        local un = xmlFindChild(xml, "username", 0)
        local pw = xmlFindChild(xml, "password", 0)
        local user = un and (xmlNodeGetValue(un) or "") or ""
        local pass = pw and (xmlNodeGetValue(pw) or "") or ""
        xmlUnloadFile(xml)
        return user, pass
end

-- music ----------------------------------------------------------------------
local function stopLoginMusic()
        if isElement(music) then
                if isTimer(fadeout_sound_timer) then killTimer(fadeout_sound_timer) end
                fadeout_sound_timer = setTimer(function()
                        if not isElement(music) then return end
                        local v = getSoundVolume(music)
                        setSoundVolume(music, v - 0.1)
                        if v - 0.1 <= 0 then
                                destroyElement(music)
                                music = nil
                        end
                end, 500, 10)
        end
end

local function loginMusicEnabled()
        local res = getResourceFromName("settings")
        if not res or getResourceState(res) ~= "running" then
                return true
        end
        local ok, value = pcall(function() return exports.settings:getSetting("Login:music") end)
        if ok and value == true then
                return true
        end
        if type(loadSavedData) == "function" then
                local stored = loadSavedData("Login:music", "1")
                if stored == "0" or stored == "false" then
                        return false
                end
        end
        return true
end

local function startLoginMusic()
        if not loginMusicEnabled() then
                stopLoginMusic()
                return
        end
        if not isElement(music) then
                music = playSound("menu.mp3", true)
                if isElement(music) then setSoundVolume(music, 0.45) end
        end
end

-- camera intro ----------------------------------------------------------------
local CAMERA_POINTS = {
        { 1630.4, -2284.0, 90.0, 1630.4, -2284.0, 60.0 },
        { 1479.6, -1750.0, 60.0, 1479.6, -1750.0, 30.0 },
        { 2358.7, 2361.2, 40.0, 2358.7, 2361.2, 20.0 },
}

local function drawBackground()
        -- [Fix #54 - user] تخفيف التغميق: 180 -> 120 (login was too dark)
        dxDrawRectangle(0, 0, sx, sy, tocolor(0, 3, 8, 120), true)
end

local loadingRenderAdded = false

local function drawLoading()
        local rot = (getTickCount() % 500) / 500 * 360
        dxDrawImage(sx - 80, sy - 80, 50, 50, "login-panel/images/Loading.png", rot, 0, 0, tocolor(255, 255, 255, 255), true)
end

local function showLoading(on)
        -- [Fix #45] there is no `public` resource on this server, so the plain
        -- `exports.public ...` check raised "Call to non-running server
        -- resource" every time. Guard on the real resource state instead.
        local res = getResourceFromName("public")
        if res and getResourceState(res) == "running" then
                pcall(function()
                        exports.public:loading("login", on)
                end)
        end
        if on then
                if not loadingRenderAdded then
                        addEventHandler("onClientRender", root, drawLoading)
                        loadingRenderAdded = true
                end
        elseif loadingRenderAdded then
                removeEventHandler("onClientRender", root, drawLoading)
                loadingRenderAdded = false
        end
end

function setLoginPanelVisible(state)
        if not built then return end -- [Fix #45] nothing to show before buildUI succeeds
        visible = state
        if state then
                eui:uiSetVisible(UI.window.login, true)
                showContainer("login")
                showCursor(true)
        else
                eui:uiSetVisible(UI.window.login, false)
                showCursor(false)
        end
end

function setModeScreenVisible(state)
        if not UI.label.ModeScreen then return end
        eui:uiSetVisible(UI.label.ModeScreen, state)
        local mode = getElementData(resourceRoot, "Mode")
        local msg = mode == "closed" and "السيرفر مغلق حالياً — Server is closed"
                or mode == "restart" and "السيرفر يعيد التشغيل — Restarting, try again shortly"
                or tostring(mode or "")
        eui:uiSetText(UI.label.ModeMessage, msg)
end

-- build ------------------------------------------------------------------------
local function buildUI()
        if built then return true end
        if not ensureUIKit() then
                -- [Fix #45] UIKit is not running yet: leave `built` false so
                -- the next beginLogin attempt rebuilds instead of shipping
                -- an empty panel.
                return false
        end

        UI.image.Logo = eui:uiCreateImage((sx - 148) / 2, (sy - 150) / 2 - 148, 148, 148, ":main-menu/images/logo.png")
        eui:uiSetVisible(UI.image.Logo, false)

        -- [Fix #43] the Mode screen label was created WITHOUT its text argument;
        -- uiCreateLabel indexes arg4.en unconditionally, so this raised inside
        -- the export every build (contained by MTA, leaving ModeScreen nil and
        -- the closed-server/restart message dead). Give it a real text + align.
        UI.label.ModeScreen = eui:uiCreateLabel(sx * 0.6, 0, sx * 0.4, sy, "", tocolor(255, 255, 255, 255), "center", "center")
        eui:uiSetVisible(UI.label.ModeScreen, false)
        UI.label.ModeMessage = eui:uiCreateLabel(0, 0, sx * 0.4, sy, "", tocolor(255, 255, 255, 255), "center", "center")
        eui:uiSetFont(UI.label.ModeScreen, "default-large")
        eui:uiSetFont(UI.label.ModeMessage, "default-large")

        UI.window.login = eui:uiCreateRectangle(false, false, 350, 500, tocolor(6, 9, 14, 250), true, true, true, true)
        eui:uiSetVisible(UI.window.login, false)
        eui:uiBringToFront(UI.window.login)
        eui:uiCreateRectangle((350 - 175) / 2, 0, 175, 5, "primary", false, false, false, false, UI.window.login)
        eui:uiCreateRectangle((350 - 175) / 2, 495, 175, 5, "primary", false, false, false, false, UI.window.login)

        local ox, oy = (350 - 305) / 2, (500 - 410) / 2
        UI.container.login = eui:uiCreateContainer(ox, oy, 305, 410, UI.window.login)
        UI.container.register = eui:uiCreateContainer(ox, oy, 305, 410, UI.window.login)
        eui:uiSetVisible(UI.container.register, false)

        -- ---------------- LOGIN container ----------------
        UI.image.usericon = eui:uiCreateImage((305 - 100) / 2, 0, 100, 100, ":main-menu/images/logo.png", UI.container.login)
        eui:uiSetColor(UI.image.usericon, 255, 255, 255, 180)
        UI.label.Title = eui:uiCreateLabel(0, 110, 305, 30, "Login", tocolor(255, 255, 255, 255), "center", "center", UI.container.login)
        eui:uiSetFont(UI.label.Title, "default-large")

        UI.rect.Username = eui:uiCreateRectangle(10, 170, 285, 40, tocolor(19, 22, 27, 255), true, true, true, true, UI.container.login)
        eui:uiSetColor(eui:uiCreateImage(8, 12.5, 15, 15, "login-panel/images/user_icon.png", UI.rect.Username), 255, 255, 255, 180)
        UI.edit.Username = eui:uiCreateEdit(25, 4, 250, 35, "", "Username", _, UI.rect.Username)

        UI.rect.Password = eui:uiCreateRectangle(10, 220, 285, 40, tocolor(19, 22, 27, 255), true, true, true, true, UI.container.login)
        eui:uiSetColor(eui:uiCreateImage(8, 12.5, 15, 15, "login-panel/images/password_icon.png", UI.rect.Password), 255, 255, 255, 180)
        UI.edit.Password = eui:uiCreateEdit(25, 4, 250, 35, "", "Password", _, UI.rect.Password)
        eui:uiEditSetMasked(UI.edit.Password, true)

        UI.label.forgot = eui:uiCreateLabel(10, 265, 285, 20, "Forgot password ?", tocolor(255, 255, 255, 150), "center", "center", UI.container.login)
        UI.checkbox.Remember = eui:uiCreateSwitch(15, 290, 200, 20, "Remember me.", false, _, UI.container.login)

        UI.button.Login = eui:uiCreateButton(10, 330, 285, 40, "Login", "primary", UI.container.login)
        eui:uiSetProperty(UI.button.Login, "HoverGlow", true)
        UI.label.toRegister = eui:uiCreateLabel(10, 385, 285, 20, "I do not have an account", tocolor(255, 255, 255, 150), "center", "center", UI.container.login)

        -- ---------------- REGISTER container ----------------
        UI.image.returnToLogin = eui:uiCreateImage(15, 19, 24, 24, "login-panel/images/left-arrow.png", UI.container.register)
        eui:uiSetProperty(UI.image.returnToLogin, "HoverOpacityEffect", true)
        UI.label.RegTitle = eui:uiCreateLabel(0, 15, 305, 30, "Create Account", tocolor(255, 255, 255, 255), "center", "center", UI.container.register)
        eui:uiSetFont(UI.label.RegTitle, "default-large")
        eui:uiCreateLabel(0, 60, 305, 40,
                "* You are only allowed to have one account *\nEmail is important to reset your password",
                tocolor(255, 255, 255, 100), "center", "center", UI.container.register)

        UI.rect["RA:Username"] = eui:uiCreateRectangle(10, 140, 285, 40, tocolor(19, 22, 27, 255), true, true, true, true, UI.container.register)
        eui:uiSetColor(eui:uiCreateImage(8, 12.5, 15, 15, "login-panel/images/user_icon.png", UI.rect["RA:Username"]), 255, 255, 255, 180)
        UI.edit["RA:Username"] = eui:uiCreateEdit(25, 4, 250, 35, "", "Username", _, UI.rect["RA:Username"])

        UI.rect["RA:Password"] = eui:uiCreateRectangle(10, 185, 285, 40, tocolor(19, 22, 27, 255), true, true, true, true, UI.container.register)
        eui:uiSetColor(eui:uiCreateImage(8, 12.5, 15, 15, "login-panel/images/password_icon.png", UI.rect["RA:Password"]), 255, 255, 255, 180)
        UI.edit["RA:Password"] = eui:uiCreateEdit(25, 4, 250, 35, "", "Password", _, UI.rect["RA:Password"])
        eui:uiEditSetMasked(UI.edit["RA:Password"], true)

        UI.rect.RePassword = eui:uiCreateRectangle(10, 230, 285, 40, tocolor(19, 22, 27, 255), true, true, true, true, UI.container.register)
        eui:uiSetColor(eui:uiCreateImage(8, 12.5, 15, 15, "login-panel/images/password_icon.png", UI.rect.RePassword), 255, 255, 255, 180)
        UI.edit.RePassword = eui:uiCreateEdit(25, 4, 250, 35, "", "Confirm Password", _, UI.rect.RePassword)
        eui:uiEditSetMasked(UI.edit.RePassword, true)

        UI.rect.Email = eui:uiCreateRectangle(10, 275, 285, 40, tocolor(19, 22, 27, 255), true, true, true, true, UI.container.register)
        eui:uiSetColor(eui:uiCreateImage(8, 12.5, 15, 15, "login-panel/images/email_icon.png", UI.rect.Email), 255, 255, 255, 180)
        UI.edit.Email = eui:uiCreateEdit(25, 4, 250, 35, "", "Email", _, UI.rect.Email)

        UI.button.Register = eui:uiCreateButton(10, 335, 285, 40, "Register", "primary", UI.container.register)
        eui:uiSetProperty(UI.button.Register, "HoverGlow", true)

        -- status label (set_warning_text / set_authen_text target)
        -- [Fix #46] it used to sit at y=525, OUTSIDE the 500px window, so every
        -- server warning ("Account doesn't exist", "Password is incorrect", ...)
        -- rendered below the panel edge - the player saw NOTHING happen. It now
        -- lives in the free band between the container (ends 455) and the bottom
        -- accent bar (495): always visible, never covering the Login button.
        UI.label.Status = eui:uiCreateLabel(10, 457, 330, 30, "", tocolor(255, 80, 80, 255), "center", "center", UI.window.login)
        eui:uiSetProperty(UI.label.Status, "color_coded", true)
        built = true -- [Fix #45] only mark built once EVERY element succeeded
        return true
end

-- container switch + logic ---------------------------------------------------
function showContainer(which)
        eui:uiSetVisible(UI.container.login, which == "login")
        eui:uiSetVisible(UI.container.register, which == "register")
end

-- [Fix #43] legacy entry point: c_login.lua and c_options.lua call the old
-- OwlGaming global which never existed in this rebuild (runtime error on
-- every login screen open). Re-open the rebuilt panel through it.
function open_log_reg_pannel()
        if not buildUI() then return end -- [Fix #45] UIKit may still be down
        setLoginPanelVisible(true)
        showContainer("login")
end

local function showWarning(tab, text)
        if UI.label.Status and isElement(UI.label.Status) then
                eui:uiSetText(UI.label.Status, tostring(text or ""))
        end
end

local function showAuthen(tab, text)
        showWarning(tab, text)
end

-- auto-login -----------------------------------------------------------------
-- [Fix #44] cancelable auto-login (adapted from the live-server hotfix):
-- when remember-me stored a full credential set the panel pre-fills it and
-- submits the login by itself so the player does not have to type. Clicking
-- any edit (or hiding the panel, or a manual Login press) cancels the
-- pending timer; a wrong saved password just shows the warning with the
-- fields editable. The visible guard also makes it a no-op while the
-- closed/restart mode screen is up.
local AUTO_LOGIN_DELAY = 3000
local autoLoginTimer = nil

local function cancelAutoLogin()
        if autoLoginTimer and isTimer(autoLoginTimer) then
                killTimer(autoLoginTimer)
        end
        autoLoginTimer = nil
end

-- [Fix #46] login-response watchdog: if the server never answers
-- accounts:login:attempt (a post-auth script error on the server used to kill
-- playerLogin mid-way and the player was left staring at a dead panel), say
-- so after 5 seconds instead of staying silent forever.
local loginWatchdog = nil
local function cancelLoginWatchdog()
        if loginWatchdog and isTimer(loginWatchdog) then
                killTimer(loginWatchdog)
        end
        loginWatchdog = nil
end
local function armLoginWatchdog()
        cancelLoginWatchdog()
        loginWatchdog = setTimer(function()
                loginWatchdog = nil
                if not visible then return end
                showWarning("Login", "Server did not respond - please reconnect (F8: reconnect) and try again.")
        end, 5000, 1)
end

-- [Fix #46] a panel control gone missing (a contained build error left the
-- edit nil) used to crash tryLogin AFTER the click - silent nothing again.
local function loginEditsReady()
        if UI.edit.Username and UI.edit.Password then return true end
        outputChatBox("[Login] Panel controls are missing - reconnect to rebuild the panel.", 255, 80, 80, false)
        return false
end

local function safeSubmit(fn)
        -- [Fix #46] ANY error inside the submit must be REPORTED, never silent
        local ok, err = pcall(fn)
        if not ok then
                outputChatBox("[Login] Panel error: " .. tostring(err), 255, 80, 80, false)
        end
end

local function scheduleAutoLogin()
        cancelAutoLogin()
        showWarning("Login", "Saved login found - signing in automatically...")
        autoLoginTimer = setTimer(function()
                autoLoginTimer = nil
                if not visible or not UI.edit.Username or not UI.edit.Password then
                        return
                end
                if #eui:uiGetText(UI.edit.Password) == 0 then
                        return
                end
                safeSubmit(tryLogin) -- [Fix #46] even the auto-login must never fail silently
        end, AUTO_LOGIN_DELAY, 1)
end

-- enter pressed inside an edit -> submit
-- [Fix #43] UIKit edits fire the custom onClientUIAccepted event on Enter
-- (bindKey "enter" -> acceptedEvent in UIKit c_process.lua); the built-in
-- onClientGUIAccepted never fires for ui-edit elements.
addEventHandler("onClientUIAccepted", root, function()
        if not visible then return end
        if source == UI.edit.Password or source == UI.edit.Username then
                safeSubmit(tryLogin)
        elseif source == UI.edit.Email then
                safeSubmit(tryRegister)
        end
end)

function tryLogin()
        if not visible then return end
        cancelAutoLogin() -- a real (manual) attempt replaces any pending auto-login
        if not loginEditsReady() then return end
        local username = eui:uiGetText(UI.edit.Username)
        local password = eui:uiGetText(UI.edit.Password)
        if #username == 0 then
                showWarning("Login", "Please enter your username!")
                return
        end
        if #password == 0 then
                showWarning("Login", "Please enter your password!")
                return
        end
        local remember = false
        if UI.checkbox.Remember then
                -- [Fix #43] the Remember control is a ui-switch, so it must be read
                -- with uiSwitchGetSelected; uiCheckBoxGetSelected asserts on the
                -- element type and failed silently -> remember was ALWAYS false and
                -- the server wiped the saved credentials on every login.
                local selected = eui:uiSwitchGetSelected(UI.checkbox.Remember)
                remember = selected == true
        end
        -- [Fix #46] arm the no-response watchdog: the server is expected to
        -- reply with set_warning_text / set_authen_text / hideLoginWindow, all
        -- of which cancel it.
        armLoginWatchdog()
        triggerServerEvent("accounts:login:attempt", localPlayer, username, password, remember)
end

function tryRegister()
        if not visible then return end
        local username = eui:uiGetText(UI.edit["RA:Username"])
        local password = eui:uiGetText(UI.edit["RA:Password"])
        local confirm = eui:uiGetText(UI.edit.RePassword)
        local email = eui:uiGetText(UI.edit.Email)
        if #username < 3 then
                showWarning("Register", "Your username must be a minimum of 3 characters!")
                return
        end
        if username:find("[;'@,%s]") then
                showWarning("Register", "Your username cannot contain ;,@' or space!")
                return
        end
        if #password < 6 then
                showWarning("Register", "Your password is too short. You must enter 6 or more characters.")
                return
        end
        if #password >= 30 then
                showWarning("Register", "Your password is too long. You must enter less than 30 characters.")
                return
        end
        if password:find("[;'@,%s]") then
                showWarning("Register", "Your password cannot contain ;,@' or space!")
                return
        end
        if password ~= confirm then
                showWarning("Register", "The passwords do not match!")
                return
        end
        if #email > 0 and not email:match("^[%w%._%-]+@[%w%._%-]+%.[%w]+$") then
                showWarning("Register", "Please enter a valid email address.")
                return
        end
        triggerServerEvent("accounts:register:attempt", localPlayer, username, password, confirm, email)
end

-- clicks ---------------------------------------------------------------------
addEventHandler("onClientUIClick", root, function()
        if not visible then return end
        if source == UI.button.Login then
                safeSubmit(tryLogin)
        elseif source == UI.button.Register then
                safeSubmit(tryRegister)
        elseif source == UI.label.toRegister then
                showContainer("register")
                showWarning(nil, "")
        elseif source == UI.image.returnToLogin then
                showContainer("login")
                showWarning(nil, "")
        elseif source == UI.label.forgot then
                outputChatBox("Password reset: contact the staff on Discord with your account name + email.", 255, 194, 14)
        elseif source == UI.edit.Username or source == UI.edit.Password or source == UI.edit.Email then
                cancelAutoLogin() -- the player wants to type, do not submit for them
        end
end)

-- server contract --------------------------------------------------------------
addEvent("beginLogin", true)
local loginRenderAdded = false
local beginLoginRetries = 0
addEventHandler("beginLogin", root, function()
        cancelLoginWatchdog() -- [Fix #46] a fresh panel cancels a stale watchdog
        if not built then
                buildUI()
                if not built then
                        -- [Fix #45] UIKit is not running yet: retry shortly
                        -- instead of dying silently (this is what used to
                        -- leave the player with no panel)
                        beginLoginRetries = beginLoginRetries + 1
                        if beginLoginRetries <= 10 then
                                setTimer(function()
                                        triggerEvent("beginLogin", localPlayer)
                                end, 1000, 1)
                        else
                                outputChatBox("Login panel failed to initialise (UIKit not running).", 255, 0, 0)
                        end
                        return
                end
        end
        beginLoginRetries = 0
        startLoginMusic()
        if getElementData(localPlayer, "character:id") then return end
        showChat(false)
        setTime(0, 0)
        setElementInterior(localPlayer, 0)
        fadeCamera(true)
        if not loginRenderAdded then -- [Fix #45] never stack duplicate renderers
                addEventHandler("onClientRender", root, drawBackground)
                loginRenderAdded = true
        end
        local pt = CAMERA_POINTS[math.random(1, #CAMERA_POINTS)]
        setTimer(function(x, y, z, tx, ty, tz)
                showLoading(false)
                local mode = getElementData(resourceRoot, "Mode")
                if mode and mode ~= "open" then
                        setModeScreenVisible(true)
                else
                        setModeScreenVisible(false)
                        setLoginPanelVisible(true)
                end
                showCursor(true)
                setCameraMatrix(x, y, z, tx, ty, tz)
        end, 2000, 1, pt[1], pt[2], pt[3], pt[4], pt[5], pt[6])
        -- [Fix #45] the panel becomes visible from the timer above; showLoading
        -- is safe (no `public` resource) but must never abort this handler
        showLoading(true)
        -- pre-fill the remembered credentials (+ kick off the auto-login)
        local user, pass = loadRemember()
        if user and #user > 0 and UI.edit.Username then
                eui:uiSetText(UI.edit.Username, user)
        end
        if pass and #pass > 0 and UI.edit.Password then
                eui:uiSetText(UI.edit.Password, pass)
                -- [Fix #43] uiSwitchSetSelected (the control is a ui-switch)
                if UI.checkbox.Remember then eui:uiSwitchSetSelected(UI.checkbox.Remember, true) end
                if user and #user > 0 then
                        scheduleAutoLogin()
                end
        end
end)

addEvent("showLoginScreen", true)
addEventHandler("showLoginScreen", root, function()
        triggerEvent("beginLogin", localPlayer)
end)

addEventHandler("onClientElementDataChange", resourceRoot, function(key)
        if key == "Mode" then
                local mode = getElementData(resourceRoot, "Mode")
                if mode and mode ~= "open" then
                        setModeScreenVisible(true)
                        setLoginPanelVisible(false)
                elseif visible or (UI.label.ModeScreen and eui:uiGetVisible(UI.label.ModeScreen)) then
                        setModeScreenVisible(false)
                        setLoginPanelVisible(true)
                end
        end
end)

addEvent("saveLoginToXML", true)
addEventHandler("saveLoginToXML", root, function(username, password)
        saveRemember(username, password)
end)

addEvent("resetSaveXML", true)
addEventHandler("resetSaveXML", root, function()
        clearRemember()
end)

addEvent("set_warning_text", true)
addEventHandler("set_warning_text", root, function(tab, text)
        cancelLoginWatchdog() -- [Fix #46] the server answered
        showWarning(tab, text)
end)

addEvent("set_authen_text", true)
addEventHandler("set_authen_text", root, function(tab, text)
        cancelLoginWatchdog() -- [Fix #46] the server answered
        showAuthen(tab, text)
end)

addEvent("accounts:register:complete", true)
addEventHandler("accounts:register:complete", root, function()
        showContainer("login")
        showAuthen(nil, "Account created! You can log in now.")
end)

function hideLoginPanel()
        visible = false
        cancelAutoLogin()
        cancelLoginWatchdog() -- [Fix #46]
        stopLoginMusic()
        if UI.window.login then eui:uiSetVisible(UI.window.login, false) end
        if UI.image.Logo then eui:uiSetVisible(UI.image.Logo, false) end
        showCursor(false)
        removeEventHandler("onClientRender", root, drawBackground)
        -- [Fix #52] the guard flag must reset together with the handler,
        -- otherwise the dark backdrop is never re-added after the first
        -- hide (logout -> login screen lost its background forever).
        loginRenderAdded = false
        showChat(true)
end

addEvent("hideLoginPanel", true)
addEventHandler("hideLoginPanel", root, hideLoginPanel)

addEvent("hideLoginWindow", true)
addEventHandler("hideLoginWindow", root, function()
        hideLoginPanel()
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
        showChat(true)
end)

-- the server waits for this before showing the panel
triggerServerEvent("onJoin", localPlayer)

