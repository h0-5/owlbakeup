-- interface - Owl old-client utility resource (Fix #59)
-- Decompiled 1:1 from arma-backupm/[rp]/interface/interface_c_decompiled.lua
-- Keeps gui-edit / gui-memo keyboard input working while focused.

addEventHandler("onClientGUIFocus", root, function()
	if getElementType(source) == "gui-edit" or getElementType(source) == "gui-memo" then
		guiSetInputEnabled(true)
	end
end)
addEventHandler("onClientGUIBlur", root, function()
	guiSetInputEnabled(false)
end)
