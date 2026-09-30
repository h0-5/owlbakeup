-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateEdit(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
  local element = createElement("ui-edit")
  arg5 = arg5 or ""
  if type(arg5) == "string" then
    arg5 = {en = arg5, ar = arg5}
  end
  UI.DB[element] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = arg4 or "",
    title = arg5,
    colors = {
      arg6 or theme.COLORS.primary
    },
    animation = {
      getTickCount(),
      false
    },
    data = {
      masked = false,
      readonly = false,
      maxlength = -1,
      caret = 1,
      shading = {1, 1}
    },
    font = {name = dxFont, size = 1},
    properties = {
      Disabled = {
        value = "False",
        valueType = "string",
        acceptedValues = {"True", "False"}
      },
      DisableFocus = {
        value = "False",
        valueType = "string",
        acceptedValues = {"True", "False"}
      },
      UnderLineVisible = {
        value = "True",
        valueType = "string",
        acceptedValues = {"True", "False"}
      }
    }
  }
  addUIElement(element, arg7, sourceResource)
  return (element)
end
function uiEditSetReadOnly(arg0, arg1)
  assert(isUIElement(arg0, "edit"), "Bad argument @ 'uiEditSetReadOnly' [Expected ui-editbox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "boolean", "Bad argument @ 'uiEditSetReadOnly' [Expected boolean at argument 2, got " .. type(arg1) .. "]")
  UI.DB[arg0].data.readonly = arg1
  return true
end
function uiEditSetMaxLength(arg0, arg1)
  assert(isUIElement(arg0, "edit"), "Bad argument @ 'uiEditSetMaxLength' [Expected ui-editbox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiEditSetMaxLength' [Expected number at argument 2, got " .. type(arg1) .. "]")
  UI.DB[arg0].data.maxlength = arg1
  return true
end
function uiEditSetCaretIndex(arg0, arg1)
  assert(isUIElement(arg0, "edit"), "Bad argument @ 'uiEditSetCaretIndex' [Expected ui-editbox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiEditSetCaretIndex' [Expected number at argument 2, got " .. type(arg1) .. "]")
  if arg1 ~= UI.DB[arg0].data.caret then
    UI.DB[arg0].data.caret = math.max(math.min(arg1, utfLen(UI.DB[arg0].text) + 1), 1)
    triggerEvent("onClientUICaretPositionChange", arg0, arg1)
    return true
  end
  return false
end
function uiEditIsReadOnly(arg0)
  assert(isUIElement(arg0, "edit"), "Bad argument @ 'uiEditIsReadOnly' [Expected ui-editbox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.readonly
end
function uiEditIsMasked(arg0)
  assert(isUIElement(arg0, "edit"), "Bad argument @ 'uiEditIsMasked' [Expected ui-editbox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.masked
end
function uiEditGetMaxLength(arg0)
  assert(isUIElement(arg0, "edit"), "Bad argument @ 'uiEditGetMaxLength' [Expected ui-editbox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.maxlength
end
function uiEditGetCaretIndex(arg0)
  assert(isUIElement(arg0, "edit"), "Bad argument @ 'uiEditGetCaretIndex' [Expected ui-editbox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.caret
end
function uiEditSetMasked(arg0, arg1)
  assert(isUIElement(arg0, "edit"), "Bad argument @ 'uiEditSetMasked' [Expected ui-editbox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].data.masked = arg1
end
function uiEditSetTitle(arg0, arg1)
  assert(isUIElement(arg0, "edit"), "Bad argument @ 'uiEditSetTitle' [Expected ui-editbox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  arg1 = arg1 or ""
  if type(arg1) == "string" then
    arg1 = {en = arg1, ar = arg1}
  end
  UI.DB[arg0].title = arg1
end
UI.getDrawFunction["ui-edit"] = function(arg0)
  -- [Vortex fix #10] the decompiler inlined the password-mask display
  -- unconditionally; the original honored data.masked (uiEditSetMasked).
  local shown = UI.DB[arg0].data.masked and shown or tostring(UI.DB[arg0].text)

  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  if UI.DB[arg0].properties.UnderLineVisible.value == "True" then
    dxDrawLine(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - 2, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - 2, noActiveColor or tocolor(50, 50, 50, 255), 2, UI.postGUI)
    if UI.FocusElement == arg0 then
      dxDrawLine(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - 2, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - 2, UI.DB[arg0].colors[1], 2, UI.postGUI)
    end
  end
  dxDrawText(shown == "" and UI.DB[arg0].title[language] or shown, UI.DB[arg0].dimensions.x + 7, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 7, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - 2, tocolor(255, 255, 255, math.max(shown == "" and anim(UI.DB[arg0].animation[1], 500, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2, 0, 180, 0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.width, 255, 0, "Linear") - 155 or anim(UI.DB[arg0].animation[1], 500, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2, 0, 180, 0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.width, 255, 0, "Linear"))), UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].dimensions.x + dxGetTextWidth(utfSub(shown, 1, UI.DB[arg0].data.caret - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name) + 5 <= UI.DB[arg0].dimensions.x - 5 + UI.DB[arg0].dimensions.width and "left" or "left", "center", true, false, UI.postGUI, false, false)
  if UI.DB[arg0].data.shading[1] ~= UI.DB[arg0].data.shading[2] then
    dxDrawRectangle(UI.DB[arg0].dimensions.x + 7 + dxGetTextWidth(utfSub(shown, 1, UI.DB[arg0].data.shading[1] - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name), UI.DB[arg0].dimensions.y + 2, UI.DB[arg0].dimensions.x + 7 + dxGetTextWidth(utfSub(shown, 1, UI.DB[arg0].data.shading[1] - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name) + dxGetTextWidth(utfSub(shown, UI.DB[arg0].data.shading[1], UI.DB[arg0].data.shading[2] - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name) > UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 7 and UI.DB[arg0].dimensions.width - (UI.DB[arg0].dimensions.x + 7 + dxGetTextWidth(utfSub(shown, 1, UI.DB[arg0].data.shading[1] - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name) - (UI.DB[arg0].dimensions.x + 7)) - 14 or dxGetTextWidth(utfSub(shown, UI.DB[arg0].data.shading[1], UI.DB[arg0].data.shading[2] - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name), UI.DB[arg0].dimensions.height - 6, tocolor(50, 50, 50, 150), UI.postGUI)
  end
  if UI.FocusElement == arg0 then
    dxDrawLine(math.min(UI.DB[arg0].dimensions.x + 7 + dxGetTextWidth(utfSub(shown, 1, UI.DB[arg0].data.caret - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name), UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 7), UI.DB[arg0].dimensions.y + 2, math.min(UI.DB[arg0].dimensions.x + 7 + dxGetTextWidth(utfSub(shown, 1, UI.DB[arg0].data.caret - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name), UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 7), UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - 4, tocolor(dxGetColor(UI.FocusElement == arg0 and UI.DB[arg0].colors[1] or tocolor(50, 50, 50, 255))), 2, UI.postGUI)
  end
end
function shadeAllEditText(arg0, arg1)
  if (getKeyState("lctrl") or getKeyState("rctrl")) and UI.FocusElement and getElementType(UI.FocusElement) == "ui-edit" then
    UI.DB[UI.FocusElement].data.shading[1] = 1
    UI.DB[UI.FocusElement].data.shading[2] = utfLen(UI.DB[UI.FocusElement].text) + 1
    UI.DB[UI.FocusElement].data.shading[3] = 1
    uiEditSetCaretIndex(UI.FocusElement, utfLen(UI.DB[UI.FocusElement].text) + 1)
  end
end
bindKey("A", "down", shadeAllEditText)
function moveCursor(arg0, arg1, arg2, arg3)
  if not isUIElement(UI.FocusElement, "edit") then
    removeEventHandler("onClientCursorMove", root, moveCursor)
    return
  end
  UI.DB[UI.FocusElement].data.caret = getCaretFromCursorPosition(UI.DB[UI.FocusElement].dimensions.x + 7, UI.DB[UI.FocusElement].text, arg2, UI.FocusElement)
  if getCaretFromCursorPosition(UI.DB[UI.FocusElement].dimensions.x + 7, UI.DB[UI.FocusElement].text, arg2, UI.FocusElement) < UI.DB[UI.FocusElement].data.shading[1] then
    UI.DB[UI.FocusElement].data.shading[2] = UI.DB[UI.FocusElement].data.shading[3]
    UI.DB[UI.FocusElement].data.shading[1] = getCaretFromCursorPosition(UI.DB[UI.FocusElement].dimensions.x + 7, UI.DB[UI.FocusElement].text, arg2, UI.FocusElement)
  elseif getCaretFromCursorPosition(UI.DB[UI.FocusElement].dimensions.x + 7, UI.DB[UI.FocusElement].text, arg2, UI.FocusElement) > UI.DB[UI.FocusElement].data.shading[1] then
    UI.DB[UI.FocusElement].data.shading[2] = getCaretFromCursorPosition(UI.DB[UI.FocusElement].dimensions.x + 7, UI.DB[UI.FocusElement].text, arg2, UI.FocusElement)
  end
end
function uiEditGetShadedText(arg0)
  if not isUIElement(arg0, "edit") then
    return false
  end
  if UI.DB[arg0].data.shading[1] == UI.DB[arg0].data.shading[2] then
    return false
  else
    return utfSub(UI.DB[arg0].text, UI.DB[arg0].data.shading[1], UI.DB[arg0].data.shading[2] - 1)
  end
end
function getCaretFromCursorPosition(arg0, arg1, arg2, arg3)
  local idx = 0
  if arg2 > arg0 + dxGetTextWidth(arg1, UI.DB[arg3].font.size, UI.DB[arg3].font.name) then
    idx = utfLen(arg1)
  elseif arg2 >= arg0 then
    idx = utfLen(arg1)
    for i = 1, utfLen(arg1) do
      if arg2 <= arg0 + dxGetTextWidth(utfSub(arg1, 1, i), UI.DB[arg3].font.size, UI.DB[arg3].font.name) then
        idx = i
        break
      end
    end
  end
  return idx + 1
end
function copyText(arg0, arg1)
  if (getKeyState("lctrl") or getKeyState("rctrl")) and UI.FocusElement and getElementType(UI.FocusElement) == "ui-edit" then
    if arg0 == "x" then
      -- [Fix #76] capture the selection BEFORE resetting shading: the old code
      -- reset to {1,1} first, so Ctrl+X deleted nothing and copied "" 
      local sh1, sh2 = UI.DB[UI.FocusElement].data.shading[1], UI.DB[UI.FocusElement].data.shading[2]
      local selected = utfSub(UI.DB[UI.FocusElement].text, sh1, sh2 - 1)
      UI.DB[UI.FocusElement].data.shading = {1, 1}
      uiSetText(UI.FocusElement, utfSub(UI.DB[UI.FocusElement].text, 1, sh1 - 1) .. utfSub(UI.DB[UI.FocusElement].text, sh2, utfLen(UI.DB[UI.FocusElement].text)))
      uiEditSetCaretIndex(UI.FocusElement, sh1)
      setClipboard(selected)
      return
    end
    setClipboard((utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.shading[1], UI.DB[UI.FocusElement].data.shading[2] - 1)))
  end
end
bindKey("C", "down", copyText)
bindKey("X", "down", copyText)
