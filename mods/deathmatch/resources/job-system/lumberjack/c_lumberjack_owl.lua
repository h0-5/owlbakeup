-- Decompiled by Owl Decompiler v1.0 ([jobs]/lumberjack/client_decompiled.lua)
-- Ported 1:1 into owlbakeup (Fix #63) with one decompiler artifact repaired:
--   * var0.progressbar = the lost UI table - restored as UI.progressbar.
-- The client is the cutting progress display only: Lumberjack:ProgressState
-- ("Show"/"Hide") reading the "WM:CutProgress" elementData on the tree,
-- refreshed every 2000ms (s_lumberjack_owl drives exactly that contract).

local sx, sy = guiGetScreenSize()
local SCALE = sy / 1080

local UI = {
	progressbar = {}
}

function UIKitReady()
	eui = exports.UIKit
	UI.progressbar[1] = eui:uiCreateProgressBar((sx - 280 * SCALE) / 2, sy - 100 * SCALE, 280 * SCALE, 20 * SCALE, tocolor(100, 20, 0, 240))
	eui:uiSetVisible(UI.progressbar[1], false)
	eui:uiSetProperty(UI.progressbar[1], "background_color", tocolor(20, 20, 20, 240))
	eui:uiSetProperty(UI.progressbar[1], "progress_animation", true)
end
addEventHandler("onClientUIReady", resourceRoot, UIKitReady)
addEventHandler("onClientUIKitReady", root, UIKitReady)

function closeUIWindows()
	eui:uiSetVisible(UI.progressbar[1], false)
end
addEvent("onClientPlayerQuitFromCharacter", true)
addEventHandler("onClientPlayerQuitFromCharacter", localPlayer, closeUIWindows)
addEventHandler("onClientPlayerWasted", localPlayer, closeUIWindows)

addEvent("Lumberjack:ProgressState", true)
addEventHandler("Lumberjack:ProgressState", root, function(state, tree)
	if isTimer(ProgressTimer) then
		killTimer(ProgressTimer)
	end
	if state == "Show" then
		eui:uiSetVisible(UI.progressbar[1], true)
		eui:uiProgressBarSetProgress(UI.progressbar[1], getElementData(tree, "WM:CutProgress") or 0)
		ProgressTimer = setTimer(function(tree)
			eui:uiProgressBarSetProgress(UI.progressbar[1], getElementData(tree, "WM:CutProgress") or 0)
		end, 2000, 0, tree)
	elseif state == "Hide" then
		eui:uiSetVisible(UI.progressbar[1], false)
	end
end)
