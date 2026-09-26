--Credits to MAXIME

wdwLogin_Pannel = {}
tabPannel_Main = {}
tab_Login = {}
tab_Register = {}
local sWidth,sHeight = guiGetScreenSize()
local offsetY = 70

function open_log_reg_pannel()
	if not(isElement(wdwLogin_Pannel)) then
		fadeCamera(false)
		local sounds = {'', ''}
		local sound = 1
		local bgMusic = playSound ( '', true )
		if sound == 1 then
			setSoundVolume(bgMusic, 1)
		else
			setSoundVolume(bgMusic, 0.7)
		end
		setElementData(localPlayer, "bgMusic", bgMusic )
		showChat(false)
		showCursor(true)
		guiSetInputEnabled(true)
		local Width,Height = 350,350
		local X = (sWidth/2) - (Width/2)
		local Y = (sHeight/2) - (Height/2)


		Image = guiCreateStaticImage( 0, 0, 1920, 1200, "/login-panel/login_bg.jpeg", false )
		guiSetEnabled (Image, false)

		Login_img = guiCreateStaticImage( X, Y + 120, 350, 350, "/login-panel/login_window.png", false )
		guiSetEnabled (Login_img, false)

		--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		bLogin = guiCreateStaticImage( X + 23, Y + 349, 301, 44, "/login-panel/login.png", false )
		addEventHandler("onClientGUIClick",bLogin,onClickBtnLogin)
		addEventHandler( "onClientMouseEnter",bLogin,LoginSH)
		addEventHandler("onClientMouseLeave",bLogin,SErem)

		tUsername = guiCreateEdit(X + 20,Y + 220,310,35,"",false)
		tPassword = guiCreateEdit(X + 20,Y + 295,310,35,"",false)
		guiEditSetMaxLength ( tUsername,25)
		guiEditSetMaxLength ( tPassword,25)
		guiEditSetMasked ( tPassword, true )
		guiSetProperty( tPassword, 'MaskCodepoint', '8226' )

		addEventHandler("onClientGUIChanged", tUsername, resetLogButtons)
		addEventHandler("onClientGUIChanged", tPassword, resetLogButtons)
		addEventHandler( "onClientGUIAccepted", tUsername, startLoggingIn)
		addEventHandler( "onClientGUIAccepted", tPassword, startLoggingIn)

		lbl_about_legth = guiCreateLabel(142,42,184,18,"",false)
		guiLabelSetColor(lbl_about_legth,253,255,68)
		guiLabelSetVerticalAlign(lbl_about_legth,"center")
		guiLabelSetHorizontalAlign(lbl_about_legth,"center",false)

		checkbox_save = guiCreateCheckBox(X + 230,Y + 275,100,20,"(Remember me!)",false,false)
		guiSetFont(checkbox_save,"default-small")

		login_tab_error_msg = guiCreateLabel(X,Y + 325,364,31,"Error_login_tab",false)
		guiLabelSetColor(login_tab_error_msg,255,0,0)
		guiLabelSetVerticalAlign(login_tab_error_msg,"center")
		guiLabelSetHorizontalAlign(login_tab_error_msg,"center",false)
		guiSetFont(login_tab_error_msg,"default-bold-small")

		login_tab_authen_msg = guiCreateLabel(X,Y + 325,364,31,"Authen_login_tab",false)
		guiLabelSetColor(login_tab_authen_msg,0,255,0)
		guiLabelSetVerticalAlign(login_tab_authen_msg,"center")
		guiLabelSetHorizontalAlign(login_tab_authen_msg,"center",false)
		guiSetFont(login_tab_authen_msg,"default-bold-small")


		--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		shSignup = guiCreateStaticImage( X + 23, Y + 401, 301, 44, "/login-panel/signup.png", false ) -- A gomb
		addEventHandler("onClientGUIClick",shSignup,OnBtnRegister)
		addEventHandler( "onClientMouseEnter",shSignup,SignupSH)
		addEventHandler("onClientMouseLeave",shSignup,SErem)

		lbl_reg_top_info = guiCreateLabel(X - 70,Y + 388+offsetY,500,30,"",false)
		guiLabelSetColor(lbl_reg_top_info,255,234,55)
		guiLabelSetVerticalAlign(lbl_reg_top_info,"center")
		guiLabelSetHorizontalAlign(lbl_reg_top_info,"center",false)
		guiSetFont(lbl_reg_top_info,"default-bold-small")
		guiSetVisible(lbl_reg_top_info,false)

		edit_account_name = guiCreateEdit(X + 20,Y + 215,310,35,"",false)
		guiEditSetMaxLength ( edit_account_name,25)
		guiSetVisible(edit_account_name,false)
		addEventHandler("onClientGUIChanged", edit_account_name, resetRegButtons)

		edit__reg_tab_password = guiCreateEdit(X + 20,Y + 290,310,35,"",false)
		guiEditSetMaxLength ( edit__reg_tab_password,25)
		guiEditSetMasked ( edit__reg_tab_password, true )
		guiSetProperty(edit__reg_tab_password, 'MaskCodepoint', '8226')
		guiSetVisible(edit__reg_tab_password,false)
		addEventHandler("onClientGUIChanged", edit__reg_tab_password, resetRegButtons)

		edit__reg_tab_Repassword = guiCreateEdit(X + 20,Y + 365,310,35,"",false)
		guiEditSetMaxLength ( edit__reg_tab_Repassword,25)
		guiEditSetMasked ( edit__reg_tab_Repassword, true )
		guiSetProperty(edit__reg_tab_Repassword, 'MaskCodepoint', '8226')
		guiSetVisible(edit__reg_tab_Repassword,false)
		guiSetEnabled (edit__reg_tab_Repassword, true)
		addEventHandler("onClientGUIChanged", edit__reg_tab_Repassword, resetRegButtons)

		edit__reg_tab_email = guiCreateEdit(X + 20,Y + 435,310,35,"",false)
		guiEditSetMaxLength ( edit__reg_tab_email,100)
		--guiEditSetMasked ( edit__reg_tab_email, true )
		guiSetVisible(edit__reg_tab_email,false)
		guiSetEnabled (edit__reg_tab_email, true)
		addEventHandler("onClientGUIChanged", edit__reg_tab_email, resetRegButtons)

		--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		shRegister2 = guiCreateStaticImage( X + 182, Y + 401+6+offsetY, 143, 45, "/login-panel/register.png", false )--guiCreateStaticImage( X + 23, Y + 409, 301, 44, "/login-panel/register2.png", false )
		addEventHandler("onClientGUIClick",shRegister2,onClickBtnRegister)
		addEventHandler( "onClientMouseEnter",shRegister2,Register2SH)
		addEventHandler("onClientMouseLeave",shRegister2,SErem)
		guiSetVisible(shRegister2,false)

		shCancel = guiCreateStaticImage( X + 23, Y + 401+6+offsetY, 143, 45, "/login-panel/cancel.png", false ) -- A gomb
		addEventHandler("onClientGUIClick",shCancel,onClickCancel)
		addEventHandler( "onClientMouseEnter",shCancel,CancelSH)
		addEventHandler("onClientMouseLeave",shCancel,SErem)
		guiSetVisible(shCancel,false)

		showCursor(true)

		guiSetText(login_tab_error_msg, "")
		guiSetText(login_tab_authen_msg, "")


		local username, password = loadLoginFromXML()
		if username ~= "" then
			guiCheckBoxSetSelected ( checkbox_save, true )
			guiSetText ( tUsername, tostring(username))
			guiSetText ( tPassword, tostring(password))
		else
			guiCheckBoxSetSelected ( checkbox_save, false )
			guiSetText ( tUsername, tostring(username))
			guiSetText ( tPassword, tostring(password))
		end
	end
end

function LoginSH ()
	guiStaticImageLoadImage(bLogin, "/login-panel/sh.png" )
end

function SignupSH ()
	guiStaticImageLoadImage(shSignup, "/login-panel/signup2.png" )
end

function Register2SH ()
	guiStaticImageLoadImage(shRegister2, "/login-panel/shr.png" )
end

function CancelSH ()
	guiStaticImageLoadImage(shCancel, "/login-panel/cancel2.png" )
end

function SErem ()
guiStaticImageLoadImage(bLogin, "/login-panel/login.png" )
guiStaticImageLoadImage(shSignup, "/login-panel/signup.png" )
guiStaticImageLoadImage(shRegister2, "/login-panel/register.png" )
guiStaticImageLoadImage(shCancel, "/login-panel/cancel.png" )
end

--[[
function start_cl_resource()
	open_log_reg_pannel()
end
addEventHandler("onClientResourceStart",getResourceRootElement(getThisResource()),start_cl_resource)
]]

function loadLoginFromXML()
	local xml_save_log_File = xmlLoadFile ("/login-panel/rememberme.xml")
    if not xml_save_log_File then
        xml_save_log_File = xmlCreateFile("/login-panel/rememberme.xml", "login")
    end
    local usernameNode = xmlFindChild (xml_save_log_File, "username", 0)
    local passwordNode = xmlFindChild (xml_save_log_File, "password", 0)
    local username, password = usernameNode and exports.global:decryptString(xmlNodeGetValue(usernameNode), localPlayer) or "", passwordNode and exports.global:decryptString(xmlNodeGetValue(passwordNode), localPlayer) or ""
    xmlUnloadFile ( xml_save_log_File )
    return username, password
end

function saveLoginToXML(username, password)
    local xml_save_log_File = xmlLoadFile ("/login-panel/rememberme.xml")
    if not xml_save_log_File then
        xml_save_log_File = xmlCreateFile("/login-panel/rememberme.xml", "login")
    end
	if (username ~= "") then
		local usernameNode = xmlFindChild (xml_save_log_File, "username", 0)
		local passwordNode = xmlFindChild (xml_save_log_File, "password", 0)
		if not usernameNode then
			usernameNode = xmlCreateChild(xml_save_log_File, "username")
		end
		if not passwordNode then
			passwordNode = xmlCreateChild(xml_save_log_File, "password")
		end
		xmlNodeSetValue (usernameNode, exports.global:encryptString(username, localPlayer))
		xmlNodeSetValue (passwordNode, exports.global:encryptString(password, localPlayer))
	end
    xmlSaveFile(xml_save_log_File)
    xmlUnloadFile (xml_save_log_File)
end
addEvent("saveLoginToXML", true)
addEventHandler("saveLoginToXML", getRootElement(), saveLoginToXML)



function resetSaveXML()
	local xml_save_log_File = xmlLoadFile ("/login-panel/rememberme.xml")
    if xml_save_log_File then
		fileDelete ("/login-panel/rememberme.xml")
		xmlUnloadFile ( xml_save_log_File )
	end
end
addEvent("resetSaveXML", true)
addEventHandler("resetSaveXML", getRootElement(), resetSaveXML)

function onClickBtnLogin(button,state)
	if(button == "left" and state == "up") then
		if (source == bLogin) then
			startLoggingIn()
		end
	end
end

local loginClickTimer = nil
function startLoggingIn()
	if not getElementData(localPlayer, "clickedLogin") then
		setElementData(localPlayer, "clickedLogin", true)
		if isTimer(loginClickTimer) then
			killTimer(loginClickTimer)
		end
		loginClickTimer = setTimer(setElementData, 1000, 1, localPlayer, "clickedLogin", nil)

		username = guiGetText(tUsername)
		password = guiGetText(tPassword)
			if guiCheckBoxGetSelected ( checkbox_save ) == true then
				checksave = true
			else
				checksave = false
			end
		playSoundFrontEnd ( 6 )
		guiSetEnabled(bLogin, false)
		guiSetAlpha(bLogin, 0.3)
		triggerServerEvent("accounts:login:attempt", getLocalPlayer(), username, password, checksave)
		authen_msg("Login", "Sending request to server..")
	else
		Error_msg("Login", "Slow down..")
	end
end

function hideLoginPanel(keepBG)
	guiSetVisible(shSignup, false)
	guiSetVisible(bLogin, false)
	guiSetVisible(tPassword, false)
	guiSetVisible(tUsername, false)
	guiSetVisible(checkbox_save, false)
	guiSetVisible(Login_img, false)
	guiSetVisible(login_tab_authen_msg, false)
	showCursor(true)
	if not keepBG then
		guiSetVisible(Image, false)
		showChat(true)
	end

	removeEventHandler("onClientGUIClick",bLogin,onClickBtnLogin)
end
addEvent("hideLoginPanel", true)
addEventHandler("hideLoginPanel", getRootElement(), hideLoginPanel)


function OnBtnRegister ()
	switchToRegisterPanel() -- Disabled registration
	playSoundFrontEnd ( 2 )
	--guiSetText(login_tab_error_msg, "Please register on Owlgaming.net/register.php")
end

function onClickCancel()
	switchToLoginPanel()
	playSoundFrontEnd ( 2 )
end

function switchToLoginPanel()
	guiSetText(login_tab_error_msg, "")
	guiSetText(login_tab_authen_msg, "")
	guiSetText(lbl_reg_top_info, "")

	guiSetSize(Login_img, 350,350, false)
	guiStaticImageLoadImage(Login_img, "login-panel/Login_window.png" )
	guiSetVisible(shRegister2, false)
	guiSetVisible(shCancel,false)
	guiSetVisible(lbl_reg_top_info,false)
	guiSetVisible(edit__reg_tab_Repassword,false)
	guiSetEnabled (edit__reg_tab_Repassword, false)
	guiSetVisible(edit__reg_tab_email,false)
	guiSetEnabled (edit__reg_tab_email, false)
	guiSetVisible(edit__reg_tab_password,false)
	guiSetVisible(edit_account_name,false)
	guiSetVisible(shSignup, true)
	guiSetVisible(bLogin, true)
	guiSetVisible(tPassword, true)
	guiSetVisible(tUsername, true)
	guiSetVisible(checkbox_save, true)
	showCursor(true)
end

function switchToLoginPanel()
	guiSetText(login_tab_error_msg, "")
	guiSetText(login_tab_authen_msg, "")
	guiSetText(lbl_reg_top_info, "")

	guiSetSize(Login_img, 350,350, false)
	guiStaticImageLoadImage(Login_img, "login-panel/Login_window.png" )
	guiSetVisible(shRegister2, false)
	guiSetVisible(shCancel,false)
	guiSetVisible(lbl_reg_top_info,false)
	guiSetVisible(edit__reg_tab_Repassword,false)
	guiSetEnabled (edit__reg_tab_Repassword, false)
	guiSetVisible(edit__reg_tab_email,false)
	guiSetEnabled (edit__reg_tab_email, false)
	guiSetVisible(edit__reg_tab_password,false)
	guiSetVisible(edit_account_name,false)
	guiSetVisible(shSignup, true)
	guiSetVisible(bLogin, true)
	guiSetVisible(tPassword, true)
	guiSetVisible(tUsername, true)
	guiSetVisible(checkbox_save, true)
	showCursor(true)
	if sHeight <= 600 and getElementData(localPlayer, "switched") then
		local x, y = guiGetPosition(Login_img, false)
		guiSetPosition(Login_img, x, y+120, false)
	end
end

function switchToRegisterPanel()
	guiSetText(login_tab_error_msg, "")
	guiSetText(login_tab_authen_msg, "")
	guiSetText(lbl_reg_top_info, "")

	guiSetSize(Login_img, 350,421, false)
	guiStaticImageLoadImage(Login_img, "login-panel/register_window.png" )
	guiSetVisible(shRegister2, true)
	guiSetVisible(shCancel,true)
	guiSetVisible(lbl_reg_top_info,true)
	guiSetVisible(edit__reg_tab_Repassword,true)
	guiSetEnabled (edit__reg_tab_Repassword, true)
	guiSetVisible(edit__reg_tab_password,true)
	guiSetVisible(edit_account_name,true)
	guiSetVisible(edit__reg_tab_email,true)
	guiSetEnabled (edit__reg_tab_email, true)
	guiSetVisible(shSignup, false)
	guiSetVisible(bLogin, false)
	guiSetVisible(tPassword, false)
	guiSetVisible(tUsername, false)
	guiSetVisible(checkbox_save, false)
	showCursor(true)
	if sHeight <= 600 then
		local x, y = guiGetPosition(Login_img, false)
		guiSetPosition(Login_img, x, y-120, false)
		if not getElementData(localPlayer, "switched") then
			x, y = guiGetPosition(shRegister2, false)
			guiSetPosition(shRegister2, x, y-120, false)
			x, y = guiGetPosition(shCancel, false)
			guiSetPosition(shCancel, x, y-120, false)
			x, y = guiGetPosition(lbl_reg_top_info, false)
			guiSetPosition(lbl_reg_top_info, x, y-120, false)
			x, y = guiGetPosition(edit__reg_tab_Repassword, false)
			guiSetPosition(edit__reg_tab_Repassword, x, y-120, false)
			x, y = guiGetPosition(edit__reg_tab_password, false)
			guiSetPosition(edit__reg_tab_password, x, y-120, false)
			x, y = guiGetPosition(edit_account_name, false)
			guiSetPosition(edit_account_name, x, y-120, false)
			x, y = guiGetPosition(edit__reg_tab_email, false)
			guiSetPosition(edit__reg_tab_email, x, y-120, false)
		end
	end
	setElementData(localPlayer, "switched", true)
end

function onClickBtnRegister(button,state)
	username = guiGetText(edit_account_name)
	password = guiGetText(edit__reg_tab_password)
	passwordConfirm = guiGetText(edit__reg_tab_Repassword)
	email = guiGetText(edit__reg_tab_email)
	registerValidation(username, password, passwordConfirm,email)

	--playSoundFrontEnd ( 6 )
	guiSetEnabled(shRegister2, false)
	guiSetAlpha(shRegister2, 0.3)
end

function registerValidation(username, password, passwordConfirm, email)
	if not username or username == "" or not password or password == "" or not passwordConfirm or passwordConfirm == "" or not email or email == ""  then
		guiSetText(lbl_reg_top_info, "Please fill out all fields.")
		guiLabelSetColor ( lbl_reg_top_info, 255, 0, 0 )
		playSoundFrontEnd ( 4 )
	elseif string.len(username) < 3 then
		guiSetText(lbl_reg_top_info, "Username must be 3 characters or longer.")
		guiLabelSetColor ( lbl_reg_top_info, 255, 0, 0 )
		playSoundFrontEnd ( 4 )
	elseif string.len(username) >= 15 then
		guiSetText(lbl_reg_top_info, "Username must be less then 20 characters long.")
		guiLabelSetColor ( lbl_reg_top_info, 255, 0, 0 )
		playSoundFrontEnd ( 4 )
	elseif string.find(password, "'") or string.find(password, '"') then
		guiSetText(lbl_reg_top_info, "Password must not contain ' or "..'"')
		guiLabelSetColor ( lbl_reg_top_info, 255, 0, 0 )
		playSoundFrontEnd ( 4 )
	elseif string.len(password) < 8 then
		guiSetText(lbl_reg_top_info, "Password must be 8 characters or longer.")
		guiLabelSetColor ( lbl_reg_top_info, 255, 0, 0 )
		playSoundFrontEnd ( 4 )
	elseif password ~= passwordConfirm then
		guiSetText(lbl_reg_top_info, "Passwords mismatched!")
		guiLabelSetColor ( lbl_reg_top_info, 255, 0, 0 )
		playSoundFrontEnd ( 4 )
	elseif string.match(username,"%W") then
		guiSetText(lbl_reg_top_info, "\"!@#$\"%'^&*()\" are not allowed in username.")
		guiLabelSetColor ( lbl_reg_top_info, 255, 0, 0 )
		playSoundFrontEnd ( 4 )
	else
		local validEmail, reason = exports.global:isEmail(email)
		if not validEmail then
			guiSetText(lbl_reg_top_info, reason)
			guiLabelSetColor ( lbl_reg_top_info, 255, 0, 0 )
			playSoundFrontEnd ( 4 )
		else
			triggerServerEvent("accounts:register:attempt",getLocalPlayer(),username,password,passwordConfirm, email)
			authen_msg("Register", "Sending request to server.")
		end
	end
end

function registerComplete(username, pw, email)
	guiSetText(tUsername, username)
	guiSetText(tPassword, pw)
	playSoundFrontEnd(13)
	displayRegisterConpleteText(username, email)
end
addEvent("accounts:register:complete",true)
addEventHandler("accounts:register:complete",getRootElement(),registerComplete)

function displayRegisterConpleteText(username)
	local GUIEditor = {
	    button = {},
	    window = {},
	    label = {}
	}

	local extend = 50
	local yoffset = 200
	GUIEditor.window[1] = guiCreateWindow(667, 381, 357, 189+extend, "Congratulations! Account has been successfully created!", false)
	exports.global:centerWindow(GUIEditor.window[1])
	local x, y = guiGetPosition(GUIEditor.window[1], false)
	guiSetPosition(GUIEditor.window[1], x, y+yoffset, false)
	guiSetAlpha(GUIEditor.window[1], 1)
    guiWindowSetMovable(GUIEditor.window[1], false)
    guiWindowSetSizable(GUIEditor.window[1], false)
    guiSetProperty(GUIEditor.window[1], "AlwaysOnTop", "True")

    GUIEditor.label[1] = guiCreateLabel(8, 25, 339, 121+extend, "Your Trinity MTA account for '"..username.."' is almost ready for action!\n\nPlease visit our website for any problems:\nhttp://trinitygaming.netne.net"..username.."\n\nSincerely, Trinity  Community TrinityGaming Development Team\"", false, GUIEditor.window[1])
    guiLabelSetHorizontalAlign(GUIEditor.label[1], "left", true)
    GUIEditor.button[1] = guiCreateButton(10, 153+extend, 337, 26, "Click here to finish and copy the website to clipboard", false, GUIEditor.window[1])
    addEventHandler("onClientGUIClick", GUIEditor.button[1], function()
    	if source == GUIEditor.button[1] then
    		if isElement(GUIEditor.window[1]) then
    			destroyElement(GUIEditor.window[1])
    			GUIEditor = nil
    			switchToLoginPanel()
    			setClipboard("http://trinitygaming.netne.net"..username)
    		end
    	else
    		cancelEvent()
    	end
    end)
end

function Error_msg(Tab, Text)
showCursor(true)
	if Tab == "Login" then
		playSoundFrontEnd ( 4)
		guiSetVisible(shSignup, true)
		guiSetVisible(bLogin, true)
		guiSetVisible(tPassword, true)
		guiSetVisible(tUsername, true)
		guiSetVisible(checkbox_save, true)
		guiSetVisible(Login_img, true)

		guiSetText(login_tab_authen_msg, "")
		guiSetText(login_tab_error_msg, tostring(Text))
		--setTimer(function() guiSetText(login_tab_error_msg, "") end,3000,1)
	else
		playSoundFrontEnd ( 4)
		guiSetText(lbl_reg_top_info, tostring(Text))
		guiLabelSetColor ( lbl_reg_top_info, 255, 0, 0 )
	end
end
addEvent("set_warning_text",true)
addEventHandler("set_warning_text",getRootElement(),Error_msg)

function authen_msg(Tab, Text)
showCursor(true)
	if Tab == "Login" then
		--playSoundFrontEnd ( 12)
		guiSetVisible(shSignup, true)
		guiSetVisible(bLogin, true)
		guiSetVisible(tPassword, true)
		guiSetVisible(tUsername, true)
		guiSetVisible(checkbox_save, true)
		guiSetVisible(Login_img, true)

		guiSetText(login_tab_error_msg, "")
		guiSetText(login_tab_authen_msg, tostring(Text))
		--setTimer(function() guiSetText(login_tab_authen_msg, "") end,3000,1)
	else
		--playSoundFrontEnd ( 12 )
		guiSetText(lbl_reg_top_info, tostring(Text))
		guiLabelSetColor ( lbl_reg_top_info, 255, 255, 255 )
	end
end
addEvent("set_authen_text",true)
addEventHandler("set_authen_text",getRootElement(),authen_msg)


function hideLoginWindow()
	showCursor(false)
	showChat(true)
	hideLoginPanel()
	removeEventHandler("onClientGUIClick",bLogin,onClickBtnLogin)
end
addEvent("hideLoginWindow", true)
addEventHandler("hideLoginWindow", getRootElement(), hideLoginWindow)

function CursorError ()
showCursor(false)
end
addCommandHandler("showc", CursorError)

function resetRegButtons ()
	guiSetEnabled(shRegister2, true)
	guiSetAlpha(shRegister2, 1)
end

function resetLogButtons()
	guiSetEnabled(bLogin, true)
	guiSetAlpha(bLogin, 1)
end

