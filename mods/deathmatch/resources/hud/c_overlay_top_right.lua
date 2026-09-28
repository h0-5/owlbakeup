local localPlayer = getLocalPlayer()
local show = false
local width, height = 246,300
local sx, sy = guiGetScreenSize()
local content = {}
local timerClose = nil
local cooldownTime = 5 --seconds
local BizNoteFont20 = "default"
local toBeDrawnWidth = width
local justClicked = false
function drawOverlayTopRight(info, widthNew, posXOffsetNew, posYOffsetNew, cooldown)
	local pinned = getElementData(localPlayer, "hud:pin")
	if not pinned and timerClose and isTimer(timerClose) then
		killTimer(timerClose)
		timerClose = nil
	end
	if info then
		content = info
		content[1][1] = string.sub(content[1][1], 1, 1)..string.sub(content[1][1], 2)
	else
		return false
	end
	
	if posXOffsetNew then
		posXOffset = posXOffsetNew
	end
	if posYOffsetNew then
		posYOffset = posYOffsetNew
	end
	if cooldown then
		cooldownTime = cooldown
	end
	if content then
		show = true
	end
	
	toBeDrawnWidth = width
	
	playSoundFrontEnd ( 101 )
	if cooldownTime ~= 0 and not pinned then
		timerClose = setTimer(function()
			show = false
			setElementData(localPlayer, "hud:overlayTopRight", 0)
		end, cooldownTime*1000, 1)
	end
	
	for i=1, #info do
		outputConsole(info[i][1] or "")
	end
end
addEvent("hudOverlay:drawOverlayTopRight", true)
addEventHandler("hudOverlay:drawOverlayTopRight", localPlayer, drawOverlayTopRight)

-- [Fix #47 - FPS] stop per-frame element-data writes: "hud:overlayTopRight"
-- was written EVERY FRAME (sync + change-event churn for every listener).
-- The PM-preview gate is cached on data change instead of polled per frame.
local lastOverlayHeight = nil
local cachedPMPreview = false
addEventHandler("onClientElementDataChange", localPlayer, function(key)
        if key == "integration:previewPMShowing" then
                cachedPMPreview = getElementData(localPlayer, "integration:previewPMShowing") == true
        end
end, false)
addEventHandler("onClientResourceStart", resourceRoot, function()
        cachedPMPreview = getElementData(localPlayer, "integration:previewPMShowing") == true
end)

addEventHandler("onClientRender",getRootElement(), function ()
	if show and not cachedPMPreview then 
		if ( getPedWeapon( localPlayer ) ~= 43 or not getControlState( "aim_weapon" ) ) then
			local posXOffset, posYOffset = 0, 0
			local hudDxHeight = getElementData(localPlayer, "hud:whereToDisplayY") or 0
			if hudDxHeight then
				posYOffset = posYOffset + hudDxHeight + 40
			end
			
			local reportDxHeight = getElementData(localPlayer, "report-system:dxBoxHeight") or 0
			if reportDxHeight then
				posYOffset = posYOffset + reportDxHeight
			end
			dxDrawImage(sx-toBeDrawnWidth-5+posXOffset, 5+posYOffset, toBeDrawnWidth, 16*(#content)+30, "images/hud/box.png")
			
			if isCursorShowing() then
				local cursorX, cursorY, cwX, cwY, cwZ = getCursorPosition()
				cursorX, cursorY = cursorX * screenWidth, cursorY * screenHeight
			end
			
			local newOverlayHeight = 16*(#content)+30+5
                        if newOverlayHeight ~= lastOverlayHeight then
                                lastOverlayHeight = newOverlayHeight
                                setElementData(localPlayer, "hud:overlayTopRight", newOverlayHeight)
                        end
			for i=1, #content do
				if content[i] then
					local currentWidth = dxGetTextWidth ( (content[i][1] or "" ) , 1 , "default") + 30
					if currentWidth > toBeDrawnWidth then
						toBeDrawnWidth = currentWidth
					end
					
					if i == 1 or content[i][7] == "title" then --Title
						dxDrawText( content[i][1] or "" , sx-toBeDrawnWidth+10+posXOffset, (16*i)+posYOffset, toBeDrawnWidth-5, 15, tocolor (content[i][2] or 70,content[i][3] or 200,content[i][4] or 14, content[i][5] or 255), 1, "default-bold" )
					else
						dxDrawText( content[i][1] or "" , sx-toBeDrawnWidth+10+posXOffset, (16*i)+posYOffset, toBeDrawnWidth-5, 15, tocolor ( content[i][2] or 255, content[i][3] or 255, content[i][4] or 255, content[i][5] or 255 ), content[i][6] or 1, content[i][7] or "default" )
					end
				end
			end
		end
	end
end, false)



--TO DETECT CLICK ON DX BOX / MAXIME
addEventHandler( "onClientClick", root,
	function( button, state )
		if show and button == "left" and state == "up" then
			justClicked = true
			--outputDebugString("clicked")
		end
	end
)