
---- By:DireYT
--(Edited)
----------------------------------------------------------------
----------------------------------------------------------------

local screenW,screenH = guiGetScreenSize()
local x, y =  (screenW/1024), (screenH/768)
local hudTable = {"ammo","armour","clock","health","money","weapon","wanted","area_name","vehicle_name","breath","clock","radar"}
local Fonte = dxCreateFont("Fontes/Fonte.ttf", 12.8)

----------------------------------------------------------------
----------------------------------------------------------------

local rectangleData = {
    x = screenW - 400 - 10 + 10,
    y =  77 + 40,
    width =  300,
    height = 40
}
local pdudata = {
    x = screenW - 60 - 10,
	y =  13,
	width =   15,
	height = 80
}

addEventHandler("onClientRender", root, 

function()

----------------------------------------------------------------
----------------------------------------------------------------

	local Vida = getElementHealth(getLocalPlayer())
	local Fome = getElementData(getLocalPlayer(), "hungrey") or 100
	local Sede = getElementData(getLocalPlayer(), "wanter") or 100
	local Colete = getPedArmor(getLocalPlayer()) or 100
	--local Empregos = getElementData(getLocalPlayer(), "Emprego") or "GreenCountry-Rp"
    local Stamina = tonumber(getElementData(localPlayer, "stamina") or 100)
    local Dinheiro = getElementData(localPlayer,"money") or 0
    local Banco = getElementData(localPlayer, "bankmoney") or 0

----------------------------------------------------------------
----------------------------------------------------------------

    --dxDrawImage(screenW - 125 - 10, - 2, 125, 117, "Imagens/Logo.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
   -- dxDrawImage(screenW - 205 - 10, 140, 31, 30, "Imagens/Fundo.png", 0, 0, 0, tocolor(15, 15, 15, 170), false)
    dxDrawImage(screenW - 77 - 10, 53, 31, 30, "Imagens/Fundo.png", 0, 0, 0, tocolor(15, 15, 15, 170), false)
   -- dxDrawImage(screenW - 120 - 10, 140, 31, 30, "Imagens/Fundo.png", 0, 0, 0, tocolor(15, 15, 15, 170), false)
    --dxDrawImage(screenW - 77 - 10, 140, 31, 30, "Imagens/Fundo.png", 0, 0, 0, tocolor(15, 15, 15, 170), false)
    dxDrawImage(screenW - 34 - 10, 53, 31, 30, "Imagens/Fundo.png", 0, 0, 0, tocolor(15, 15, 15, 170), false)
--  - 1320, 53, 33, 31, 30
    dxDrawImage(screenW - 71 - 9, 60, 18, 20, "Imagens/Vida.png", 0, 0, 0, tocolor(255, 255, 255, 255), true)
   -- dxDrawImage(screenW - 156 - 10, 146, 18, 18, "Imagens/Colete.png", 0, 0, 0, tocolor(255, 255, 255, 255), true)
   -- dxDrawImage(screenW - 110 - 10, 147, 12, 15, "Imagens/Fome.png", 0, 0, 0, tocolor(255, 255, 255, 255), true)
   -- dxDrawImage(screenW - 67.5 - 10, 145, 13, 18, "Imagens/Sede.png", 0, 0, 0, tocolor(255, 255, 255, 255), true)
    dxDrawImage(screenW - 26 - 10, 60, 16, 17, "Imagens/Stamina.png", 0, 0, 0, tocolor(255, 255, 255, 255), true)

    dxDrawImageSection(screenW - 332 - 10 + 255, 61 + -10 + 33, 31, -(31*(Vida/100)), 0, 0, 35, -(35*(Vida/100)), "Imagens/Fundo_3.png", 0, 0, 0, tocolor(255, 255, 255, 170), false)
   -- dxDrawImageSection(screenW - 332 - 10 + 255, 61 + 77 + 33, 31, -(31*(Sede/100)), 0, 0, 35, -(35*(Sede/100)), "Imagens/Fundo_1.png", 0, 0, 0, tocolor(255, 255, 255, 170), false)
    --dxDrawImageSection(screenW - 374.5 - 10 + 255, 61 + 77 + 33, 31, -(31*(Fome/100)), 0, 0, 35, -(35*(Fome/100)), "Imagens/Fundo_2.png", 0, 0, 0, tocolor(197, 178, 20, 170), false)
   -- dxDrawImageSection(screenW - 418 - 10 + 255, 61 + 77 + 33, 31, -(31*(Colete/100)), 0, 0, 35, -(35*(Colete/100)), "Imagens/Fundo_3.png", 0, 0, 0, tocolor(20, 198, 184, 170), false)
    dxDrawImageSection(screenW - 289 - 10 + 255, 61 + - 10 + 33, 31, -(31*(Stamina/100)), 0, 0, 35, -(35*(Stamina/100)), "Imagens/Fundo_2.png", 0, 0, 0, tocolor(255, 255, 255, 170), false)

    dxDrawImage(screenW - 129 - 10, 90, 128, 24, "Imagens/Fundo_Money.png", 0, 0, 0, tocolor(15, 15, 15, 170), false)
    dxDrawImage(screenW - 279 - 10, 90, 128, 24, "Imagens/Fundo_Money.png", 0, 0, 0, tocolor(15, 15, 15, 170), false)
    dxDrawImage(screenW - 282 - 10, 88, 33, 32, "Imagens/Fundo.png", 0, 0, 0, tocolor(89, 214, 39, 255), false)
    dxDrawImage(screenW - 133 - 10, 88, 33, 32, "Imagens/Fundo.png", 0, 0, 0, tocolor(226, 37, 28, 255), false)        
    dxDrawImage(screenW - 273 - 10, 94, 16, 16, "Imagens/Money.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)
    dxDrawImage(screenW - 127 - 10, 94, 18, 15, "Imagens/Banco.png", 0, 0, 0, tocolor(255, 255, 255, 255), false)

    --dxDrawText(Empregos, screenW - 140 - 10, 10 + 200, screenW - 328 - 10 + 315, 20, tocolor(0, 0, 255, 0), 1.2, Fonte, "center", "center", false, false, false, false, false)
    dxDrawText(Dinheiro, screenW - 328 - 10, 10 + 84, screenW - 350 - 10 + 170, 20, tocolor ( 255, 255, 255, 255 ), 0.7, Fonte, "right", "top", false, false, false, true )
    dxDrawText(Banco, screenW - 328 - 10, 10 + 84, screenW - 321 - 10 + 280, 20, tocolor ( 255, 255, 255, 255 ), 0.7, Fonte, "right", "top", false, false, false, true )

----------------------------------------------------------------
----------------------------------------------------------------

end)
addEventHandler("accounts:characters:spawn", getRootElement(), characters_onSpawn , function()
	for id, hudComponents in ipairs(hudTable) do
		showPlayerHudComponent(hudComponents, false)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------

function dobozbaVan(dX, dY, dSZ, dM, eX, eY)
	if(eX >= dX and eX <= dX+dSZ and eY >= dY and eY <= dY+dM) then
		return true
	else
		return false
	end
end

----------------------------------------------------------------
----------------------------------------------------------------