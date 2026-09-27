-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function isMouseInPosition(arg0, arg1, arg2, arg3)
  if not isCursorShowing() then
    return false
  end
  -- [Vortex fix] the Owl decompiler inlined getCursorPosition() 4 times and
  -- Lua keeps only the FIRST return value, so every Y check compared against
  -- cursorX * sy -- hover zones collapsed into a narrow diagonal band and
  -- UI.HoveredElement was never promoted (no button/menu/tab was clickable)
  local cx, cy = getCursorPosition()
  if not cx then
    return false
  end
  cx, cy = cx * sx, cy * sy
  return arg0 <= cx and arg1 <= cy and cx <= arg0 + arg2 and cy <= arg1 + arg3
end
function dxGetColor(arg0)
  if not arg0 then
    return 255, 255, 255, 255
  end
  if theme.COLORS[arg0] then
    arg0 = theme.COLORS[arg0]
  end
  return bitExtract(arg0, 16, 8), bitExtract(arg0, 8, 8), bitExtract(arg0, 0, 8), (bitExtract(arg0, 24, 8))
end
-- [Vortex fix] default rounded-corner options (lost global restored)
local ROUNDED_ALL = { up = { left = true, right = true }, down = { left = true, right = true } }
function dxDrawRoundedRectangle(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
  arg2, arg3, arg0, arg1 = arg2 - arg5 * 2, arg3 - arg5 * 2, arg0 + arg5, arg1 + arg5
  dxDrawRectangle(arg0 - arg5, arg1, arg2 + arg5 * 2, arg3, arg4, UI.postGUI)
  dxDrawRectangle(arg0, arg1 - arg5, arg2, arg5, arg4, UI.postGUI)
  dxDrawRectangle(arg0, arg1 + arg3, arg2, arg5, arg4, UI.postGUI)
  if (type(arg6) == "table" and arg6 or ROUNDED_ALL).up.left then
    dxDrawCircle(arg0, arg1, arg5, 180, 270, arg4, arg4, 12 * SCALE_Y, _, UI.postGUI)
  else
    dxDrawRectangle(arg0 - arg5, arg1 - arg5, arg5, arg5, arg4, UI.postGUI)
  end
  if (type(arg6) == "table" and arg6 or ROUNDED_ALL).up.right then
    dxDrawCircle(arg0 + arg2, arg1, arg5, 270, 360, arg4, arg4, 12 * SCALE_Y, _, UI.postGUI)
  else
    dxDrawRectangle(arg0 + arg2, arg1 - arg5, arg5, arg5, arg4, UI.postGUI)
  end
  if (type(arg6) == "table" and arg6 or ROUNDED_ALL).down.left then
    dxDrawCircle(arg0, arg1 + arg3, arg5, 90, 180, arg4, arg4, 12 * SCALE_Y, _, UI.postGUI)
  else
    dxDrawRectangle(arg0 - arg5, arg1 + arg3, arg5, arg5, arg4, UI.postGUI)
  end
  if (type(arg6) == "table" and arg6 or ROUNDED_ALL).down.right then
    dxDrawCircle(arg0 + arg2, arg1 + arg3, arg5, 0, 90, arg4, arg4, 12 * SCALE_Y, _, UI.postGUI)
  else
    dxDrawRectangle(arg0 + arg2, arg1 + arg3, arg5, arg5, arg4, UI.postGUI)
  end
end
function dxDrawOutlinedRoundedRectangle(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
  arg2, arg3, arg0, arg1 = arg2 - arg5 * 2, arg3 - arg5 * 2, floor(arg0 + arg5), floor(arg1 + arg5)
  arg6, arg7 = arg6 or 2, arg7 or tocolor(0, 0, 0)
  dxDrawRectangle(arg0 - arg5, arg1, arg2 + arg5 * 2, arg3, arg4, UI.postGUI)
  dxDrawRectangle(arg0, arg1 - arg5, arg2, arg5, arg4, UI.postGUI)
  dxDrawRectangle(arg0, arg1 + arg3, arg2, arg5, arg4, UI.postGUI)
  dxDrawCircle(arg0, arg1, arg5, 180, 270, arg4, arg4, arg8 or 7, _, UI.postGUI)
  dxDrawCircle(arg0 + arg2, arg1, arg5, 270, 360, arg4, arg4, arg8 or 7, _, UI.postGUI)
  dxDrawCircle(arg0, arg1 + arg3, arg5, 90, 180, arg4, arg4, arg8 or 7, _, UI.postGUI)
  dxDrawCircle(arg0 + arg2, arg1 + arg3, arg5, 0, 90, arg4, arg4, arg8 or 7, _, UI.postGUI)
end
function isUIElement(arg0, ...)
  if not isElement(arg0) then
    return false
  end
  if #{
    ...
  } > 0 then
    for forvar6, forvar7 in ipairs({
      ...
    }) do
      if type(forvar7) == "string" and getElementType(arg0) == "ui-" .. forvar7 then
        return true
      end
    end
    return false
  end
  return getElementType(arg0):find("^ui%-%a+$")
end
function hoverUIElement(arg0, arg1, arg2, arg3, arg4)
  if isUIDisabled(arg0) then
    return false
  end
  -- [Vortex fix #12] the decompiled gate (promote only when the element
  -- equals the PREVIOUS frame's hover candidate) delayed every promotion
  -- by one frame; clicks fired inside that gap landed on a stale/false
  -- UI.HoveredElement and vanished -- fast move+click made buttons and
  -- gridlist rows feel 'visual only'. Promote immediately (painter order:
  -- the last drawn element under the cursor wins, same as hoverCandidate).
  UI.HoveredElement = isMouseInPosition(arg1, arg2, arg3, arg4) and arg0 or UI.HoveredElement
  return true
end
function isUIDisabled(arg0)
  return UI.DB[arg0].properties.Disabled.value == "True" or UI.TempDisabled[arg0]
end
function dxDrawEmptyLine(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
  dxDrawLine(arg0, arg1, arg0 + arg2, arg1, arg4, arg5, arg6)
  dxDrawLine(arg0, arg1, arg0, arg1 + arg3, arg4, arg5, arg6)
  dxDrawLine(arg0, arg1 + arg3, arg0 + arg2, arg1 + arg3, arg4, arg5, arg6)
  dxDrawLine(arg0 + arg2, arg1, arg0 + arg2, arg1 + arg3, arg4, arg5, arg6)
end
function anim(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
  if arg1 < getTickCount() - arg0 then
    return arg6, arg7, arg8, arg9
  end
  return interpolateBetween(arg2, arg3, arg4, arg6, arg7, arg8, (getTickCount() - arg0) / arg1, arg10)
end
function table.find(arg0, arg1)
  for forvar5, forvar6 in pairs(arg0) do
    if forvar6 == arg1 then
      return forvar5
    end
  end
  return false
end
function isEventHandlerAdded(arg0, arg1, arg2)
  if type(arg0) == "string" and isElement(arg1) and type(arg2) == "function" and type((getEventHandlers(arg0, arg1))) == "table" and #getEventHandlers(arg0, arg1) > 0 then
    for forvar7, forvar8 in ipairs((getEventHandlers(arg0, arg1))) do
      if forvar8 == arg2 then
        return true
      end
    end
  end
  return false
end
function formatText(arg0)
  if type(arg0) ~= "string" then
    return arg0
  end
  -- [Vortex fix] dxGetColor returns (r,g,b,a); forwarding all four into
  -- RGBToHex emitted an 8-digit "#RRGGBBAA" code that MTA's color_coded
  -- parser cannot read -- it consumed "#RRGGBB" and rendered the leftover
  -- "FF" as literal text in EVERY "${color.primary}" string (bullets, the
  -- Level label, the Vehicles counter...). Pass RGB only -> valid "#RRGGBB".
  local r, g, b = dxGetColor("primary")
  arg0 = string.gsub(arg0, "${color.primary}", (RGBToHex(r, g, b)) or "")
  return arg0
end
function RGBToHex(arg0, arg1, arg2, arg3)
  if arg0 < 0 or arg0 > 255 or arg1 < 0 or arg1 > 255 or arg2 < 0 or arg2 > 255 or arg3 and (arg3 < 0 or arg3 > 255) then
    return nil
  end
  if arg3 then
    return string.format("#%.2X%.2X%.2X%.2X", arg0, arg1, arg2, arg3)
  else
    return string.format("#%.2X%.2X%.2X", arg0, arg1, arg2)
  end
end
local imageCache = {}
imageCache.gradient_x = dxCreateTexture("images/gradient_x.png", "argb", true, "clamp")
imageCache.gradient_y = dxCreateTexture("images/gradient_y.png", "argb", true, "clamp")
function getUIImage(arg0)
  return imageCache[arg0]
end
function uiGetThemeColor(arg0)
  if theme.COLORS[arg0] then
    return theme.COLORS[arg0]
  end
  return false
end
addEventHandler("onClientPaste", root, function(arg0)
  triggerEvent("ui-returnClipBoard", root, arg0)
end)
