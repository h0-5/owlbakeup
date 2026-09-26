-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateMemo(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
  local element = createElement("ui-memo")
  UI.DB[element] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = arg4 or "",
    title = "",
    colors = {
      arg5 or tocolor(255, 255, 255, 255)
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
      caretLine = 1,
      shading = {1, 1},
      shadingTable = {
        {
          1,
          1,
          1
        },
        {
          1,
          1,
          1
        }
      },
      showtext = arg4,
      line_i = 1
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
      TextColor = {
        value = tocolor(0, 0, 0, 255),
        valueType = "number"
      },
      SecondColor = {
        value = theme.COLORS.primary,
        valueType = "number"
      }
    }
  }
  addUIElement(element, arg6, sourceResource)
  UI.DB[element].data.scrollbar = uiCreateScrollBar(UI.DB[element].related_dimensions_org.width - 8, 2, 6, UI.DB[element].related_dimensions_org.height - 4, theme.COLORS.scrollbar_default, tocolor(255, 255, 255, 0), false, element, tocolor(0, 0, 0, 0))
  addEventHandler("onClientUIScroll", UI.DB[element].data.scrollbar, scrollMemo)
  UI.DB[element].data.caretLine = #split(arg4, "\n")
  UI.DB[element].data.caret = utfLen(split(arg4, "\n")[#split(arg4, "\n")] or "") + 1
  adjustMemoText(0, (element))
  return (element)
end
function uiMemoSetVerticalScrollPosition(arg0, arg1)
  assert(isUIElement(arg0, "memo"), "Bad argument @ 'uiMemoSetVerticalScrollPosition' [Expected ui-memo at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiMemoSetVerticalScrollPosition' [Expected number at argument 2, got " .. type(x) .. "]")
  if UI.DB[arg0].data.scrollbar then
    uiScrollBarSetScrollPosition(UI.DB[arg0].data.scrollbar, arg1)
    return true
  end
  return false
end
function uiMemoGetVerticalScrollPosition(arg0)
  assert(isUIElement(arg0, "memo"), "Bad argument @ 'uiMemoGetVerticalScrollPosition' [Expected ui-memo at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.scrollbar and uiScrollBarGetScrollPosition(UI.DB[arg0].data.scrollbar) or 0
end
function uiMemoGetCaretIndex(arg0)
  assert(isUIElement(arg0, "memo"), "Bad argument @ 'uiMemoGetCaretIndex' [Expected ui-memo at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return utfLen((table.concat(split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10), "\n", 1, UI.DB[arg0].data.caretLine - 1):gsub("" .. newLinePrefix, ""))) + UI.DB[arg0].data.caret
end
function uiMemoSetReadOnly(arg0, arg1)
  assert(isUIElement(arg0, "memo"), "Bad argument @ 'uiMemoSetReadOnly' [Expected ui-memo at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "boolean", "Bad argument @ 'uiMemoSetReadOnly' [Expected boolean at argument 2, got " .. type(arg1) .. "]")
  UI.DB[arg0].data.readonly = arg1
  return true
end
function uiMemoIsReadOnly(arg0)
  assert(isUIElement(arg0, "memo"), "Bad argument @ 'uiEditIsReadOnly' [Expected ui-memo at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.readonly
end
function scrollMemo(arg0, arg1)
  if not isUIElement(getElementParent(source or arg1), "memo") then
    return
  end
  adjustMemoText(arg0, (getElementParent(source or arg1)))
end
function adjustMemoText(arg0, arg1)
  if not isUIElement(arg1, "memo") then
    return
  end
  UI.DB[arg1].data.showtext = table.concat(split(UI.DB[arg1].text:gsub("\n", "\n" .. newLinePrefix), 10), "\n", math.max(1, math.floor(#split(UI.DB[arg1].text:gsub("\n", "\n" .. newLinePrefix), 10) * dxGetFontHeight(UI.DB[arg1].font.size, UI.DB[arg1].font.name) / 100 * arg0 / dxGetFontHeight(UI.DB[arg1].font.size, UI.DB[arg1].font.name))), (math.min(#split(UI.DB[arg1].text:gsub("\n", "\n" .. newLinePrefix), 10), math.max(1, math.floor(#split(UI.DB[arg1].text:gsub("\n", "\n" .. newLinePrefix), 10) * dxGetFontHeight(UI.DB[arg1].font.size, UI.DB[arg1].font.name) / 100 * arg0 / dxGetFontHeight(UI.DB[arg1].font.size, UI.DB[arg1].font.name))) + math.floor(UI.DB[arg1].dimensions.height / dxGetFontHeight(UI.DB[arg1].font.size, UI.DB[arg1].font.name)) + 1))):gsub("" .. newLinePrefix, "")
  UI.DB[arg1].data.line_i = math.max(1, math.floor(#split(UI.DB[arg1].text:gsub("\n", "\n" .. newLinePrefix), 10) * dxGetFontHeight(UI.DB[arg1].font.size, UI.DB[arg1].font.name) / 100 * arg0 / dxGetFontHeight(UI.DB[arg1].font.size, UI.DB[arg1].font.name)))
  UI.DB[arg1].data.caretLine = math.max(math.min(UI.DB[arg1].data.caretLine, #split(UI.DB[arg1].text:gsub("\n", "\n" .. newLinePrefix), 10)), 1)
  UI.DB[arg1].data.caret = math.max(math.min(UI.DB[arg1].data.caret, utfLen(split(UI.DB[arg1].text:gsub("\n", "\n" .. newLinePrefix), 10)[UI.DB[arg1].data.caretLine] or "") + 1), 1)
end
UI.getDrawFunction["ui-memo"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].colors[1])), UI.postGUI)
  dxDrawText(UI.DB[arg0].data.showtext, UI.DB[arg0].dimensions.x + 7, UI.DB[arg0].dimensions.y + 7, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 7, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - 7, UI.DB[arg0].properties.TextColor.value, UI.DB[arg0].font.size, UI.DB[arg0].font.name, "left", "top", true, false, UI.postGUI, false, false)
  for forvar19 = math.max(UI.DB[arg0].data.shadingTable[1][1], UI.DB[arg0].data.line_i), UI.DB[arg0].data.shadingTable[2][1] do
    if (UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      UI.DB[arg0].text
    })[forvar19] then
      if (forvar19 ~= UI.DB[arg0].data.shadingTable[1][1] or not UI.DB[arg0].data.shadingTable[1]) and (forvar19 ~= UI.DB[arg0].data.shadingTable[2][1] or not UI.DB[arg0].data.shadingTable[2]) then
      end
      if UI.DB[arg0].dimensions.y + 7 + (({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[1] - UI.DB[arg0].data.line_i) * dxGetFontHeight(UI.DB[arg0].font.size, UI.DB[arg0].font.name) + 1 > UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - 7 then
        break
      end
      dxDrawRectangle(UI.DB[arg0].dimensions.x + 7 + dxGetTextWidth(utfSub((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[arg0].text
      })[({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[1]]:gsub("" .. newLinePrefix, ""), 1, ({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[2] - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name), UI.DB[arg0].dimensions.y + 7 + (({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[1] - UI.DB[arg0].data.line_i) * dxGetFontHeight(UI.DB[arg0].font.size, UI.DB[arg0].font.name) + 1, UI.DB[arg0].dimensions.x + 7 + dxGetTextWidth(utfSub((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[arg0].text
      })[({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[1]]:gsub("" .. newLinePrefix, ""), 1, ({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[2] - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name) + dxGetTextWidth(utfSub((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[arg0].text
      })[({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[1]]:gsub("" .. newLinePrefix, ""), ({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[2], ({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[3] - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name) > UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 7 and UI.DB[arg0].dimensions.width - (UI.DB[arg0].dimensions.x + 7 + dxGetTextWidth(utfSub((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[arg0].text
      })[({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[1]]:gsub("" .. newLinePrefix, ""), 1, ({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[2] - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name) - (UI.DB[arg0].dimensions.x + 7)) - 14 or dxGetTextWidth(utfSub((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[arg0].text
      })[({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[1]]:gsub("" .. newLinePrefix, ""), ({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[2], ({
        forvar19,
        1,
        utfLen((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[arg0].text
        })[forvar19]:gsub("" .. newLinePrefix, "")) + 1
      })[3] - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name), dxGetFontHeight(UI.DB[arg0].font.size, UI.DB[arg0].font.name) - 2, tocolor(50, 50, 50, 100), UI.postGUI)
    end
  end
  if UI.FocusElement == arg0 then
    dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, 3, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].properties.SecondColor.value or tocolor(255, 55, 95, 255))), UI.postGUI)
    dxDrawLine(math.min(UI.DB[arg0].dimensions.x + 7 + dxGetTextWidth(utfSub((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      UI.DB[arg0].text
    })[UI.DB[arg0].data.caretLine] or (""):gsub("" .. newLinePrefix, ""), 1, UI.DB[arg0].data.caret - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name), UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 7), math.max(UI.DB[arg0].dimensions.y + 7, math.min(UI.DB[arg0].dimensions.y + 7 + (UI.DB[arg0].data.caretLine - UI.DB[arg0].data.line_i) * dxGetFontHeight(UI.DB[arg0].font.size, UI.DB[arg0].font.name), UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - 7)), math.min(UI.DB[arg0].dimensions.x + 7 + dxGetTextWidth(utfSub((UI.DB[arg0].text:find("\n", 1, true) and split("" .. newLinePrefix .. UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      UI.DB[arg0].text
    })[UI.DB[arg0].data.caretLine] or (""):gsub("" .. newLinePrefix, ""), 1, UI.DB[arg0].data.caret - 1), UI.DB[arg0].font.size, UI.DB[arg0].font.name), UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 7), math.max(UI.DB[arg0].dimensions.y + 7, math.min(UI.DB[arg0].dimensions.y + 7 + (UI.DB[arg0].data.caretLine - UI.DB[arg0].data.line_i) * dxGetFontHeight(UI.DB[arg0].font.size, UI.DB[arg0].font.name) + dxGetFontHeight(UI.DB[arg0].font.size, UI.DB[arg0].font.name), UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - 7)), tocolor(dxGetColor(UI.DB[arg0].properties.SecondColor.value or tocolor(255, 55, 95, 255))), 2, UI.postGUI)
  end
end
function getLineFromCursorPosition(arg0, arg1)
  return math.min(math.max(math.floor((arg1 - UI.DB[arg0].dimensions.y + 7) / dxGetFontHeight(UI.DB[arg0].font.size, UI.DB[arg0].font.name)), 1), #(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
    UI.DB[arg0].text
  }) - UI.DB[arg0].data.line_i + 1) + (UI.DB[arg0].data.line_i - 1)
end
function enterNewLine(arg0, arg1)
  if UI.FocusElement and getElementType(UI.FocusElement) == "ui-memo" then
    if replaceShadedText(UI.FocusElement, "\n") then
      triggerEvent("onClientUITextChange", UI.FocusElement)
      return
    end
    ;(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine] = utfSub((UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""), 1, UI.DB[UI.FocusElement].data.caret - 1) .. "\n" .. utfSub((UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""), UI.DB[UI.FocusElement].data.caret, utfLen((UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine]))
    UI.DB[UI.FocusElement].text = table.concat(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    }, "\n"):gsub("" .. newLinePrefix, "")
    UI.DB[UI.FocusElement].data.showtext = table.concat(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    }, "\n", UI.DB[UI.FocusElement].data.line_i, (math.min(#(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    }), UI.DB[UI.FocusElement].data.line_i + math.floor(UI.DB[UI.FocusElement].dimensions.height / dxGetFontHeight(UI.DB[UI.FocusElement].font.size, UI.DB[UI.FocusElement].font.name)) + 1))):gsub("" .. newLinePrefix, "")
    UI.DB[UI.FocusElement].data.caret = 1
    UI.DB[UI.FocusElement].data.caretLine = math.min(UI.DB[UI.FocusElement].data.caretLine + 1, #(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    }))
    if uiMemoGetCaretIndex(UI.FocusElement) ~= uiMemoGetCaretIndex(UI.FocusElement) then
      triggerEvent("onClientUICaretPositionChange", UI.FocusElement, uiMemoGetCaretIndex(UI.FocusElement))
    end
  end
end
bindKey("enter", "down", enterNewLine)
function moveCursorForShading(arg0, arg1, arg2, arg3)
  if not isUIElement(UI.FocusElement, "memo") then
    removeEventHandler("onClientCursorMove", root, moveCursorForShading)
    return
  end
  if getLineFromCursorPosition(UI.FocusElement, arg3) == UI.DB[UI.FocusElement].data.caretLine then
    if getLineFromCursorPosition(UI.FocusElement, arg3) == UI.DB[UI.FocusElement].data.shadingTable[1][1] then
      UI.DB[UI.FocusElement].data.shadingTable[1][3] = getCaretFromCursorPosition(UI.DB[UI.FocusElement].dimensions.x + 7, (UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[UI.FocusElement].text
      })[getLineFromCursorPosition(UI.FocusElement, arg3)]:gsub("" .. newLinePrefix, ""), arg2, UI.FocusElement)
      UI.DB[UI.FocusElement].data.shadingTable[2] = UI.DB[UI.FocusElement].data.shadingTable[1]
    else
      UI.DB[UI.FocusElement].data.shadingTable[2][3] = getCaretFromCursorPosition(UI.DB[UI.FocusElement].dimensions.x + 7, (UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[UI.FocusElement].text
      })[getLineFromCursorPosition(UI.FocusElement, arg3)]:gsub("" .. newLinePrefix, ""), arg2, UI.FocusElement)
    end
    UI.DB[UI.FocusElement].data.caret = getCaretFromCursorPosition(UI.DB[UI.FocusElement].dimensions.x + 7, (UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      UI.DB[UI.FocusElement].text
    })[getLineFromCursorPosition(UI.FocusElement, arg3)]:gsub("" .. newLinePrefix, ""), arg2, UI.FocusElement)
  else
    UI.DB[UI.FocusElement].data.shadingTable[1][3] = utfLen((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      UI.DB[UI.FocusElement].text
    })[UI.DB[UI.FocusElement].data.shadingTable[1][1]]:gsub("" .. newLinePrefix, "")) + 1
    UI.DB[UI.FocusElement].data.shadingTable[2] = {
      getLineFromCursorPosition(UI.FocusElement, arg3),
      1,
      (getCaretFromCursorPosition(UI.DB[UI.FocusElement].dimensions.x + 7, (UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[UI.FocusElement].text
      })[getLineFromCursorPosition(UI.FocusElement, arg3)]:gsub("" .. newLinePrefix, ""), arg2, UI.FocusElement))
    }
    UI.DB[UI.FocusElement].data.caretLine = getLineFromCursorPosition(UI.FocusElement, arg3)
  end
  if uiMemoGetCaretIndex(UI.FocusElement) ~= uiMemoGetCaretIndex(UI.FocusElement) then
    triggerEvent("onClientUICaretPositionChange", UI.FocusElement, uiMemoGetCaretIndex(UI.FocusElement))
  end
end
function shadeAllMemoText(arg0, arg1)
  if (getKeyState("lctrl") or getKeyState("rctrl")) and UI.FocusElement and getElementType(UI.FocusElement) == "ui-memo" then
    UI.DB[UI.FocusElement].data.shadingTable[1] = {
      1,
      1,
      utfLen((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[UI.FocusElement].text
      })[1]:gsub("" .. newLinePrefix, "")) + 1
    }
    UI.DB[UI.FocusElement].data.shadingTable[2] = {
      #(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[UI.FocusElement].text
      }),
      1,
      utfLen((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[UI.FocusElement].text
      })[#(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[UI.FocusElement].text
      })]:gsub("" .. newLinePrefix, "")) + 1
    }
    UI.DB[UI.FocusElement].data.caretLine = #(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      UI.DB[UI.FocusElement].text
    })
    UI.DB[UI.FocusElement].data.caret = UI.DB[UI.FocusElement].data.shadingTable[2][3]
    if uiMemoGetCaretIndex(UI.FocusElement) ~= uiMemoGetCaretIndex(UI.FocusElement) then
      triggerEvent("onClientUICaretPositionChange", UI.FocusElement, uiMemoGetCaretIndex(UI.FocusElement))
    end
  end
end
bindKey("A", "down", shadeAllMemoText)
function replaceShadedText(arg0, arg1)
  if UI.DB[arg0].data.shadingTable[1][1] == UI.DB[arg0].data.shadingTable[2][1] and UI.DB[arg0].data.shadingTable[1][2] == UI.DB[arg0].data.shadingTable[1][3] then
    return false
  end
  if UI.DB[arg0].data.shadingTable[1][1] == UI.DB[arg0].data.shadingTable[2][1] then
  else
  end
  UI.DB[arg0].text = ((1 <= UI.DB[arg0].data.shadingTable[1][1] - 1 and table.concat(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
    UI.DB[arg0].text
  }, "\n", 1, UI.DB[arg0].data.shadingTable[1][1] - 1):gsub("" .. newLinePrefix, "") .. "\n" or "") .. utfSub((UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
    UI.DB[arg0].text
  })[UI.DB[arg0].data.shadingTable[1][1]]:gsub("" .. newLinePrefix, ""), 1, UI.DB[arg0].data.shadingTable[1][2] - 1):gsub("" .. newLinePrefix, "")) .. arg1 .. utfSub((UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
    UI.DB[arg0].text
  })[UI.DB[arg0].data.shadingTable[2][1]]:gsub("" .. newLinePrefix, ""), UI.DB[arg0].data.shadingTable[2][3], utfLen((UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
    UI.DB[arg0].text
  })[UI.DB[arg0].data.shadingTable[2][1]]:gsub("" .. newLinePrefix, ""))) .. (#(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
    UI.DB[arg0].text
  }) > UI.DB[arg0].data.shadingTable[2][1] + 1 and "\n" .. table.concat(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
    UI.DB[arg0].text
  }, "\n", UI.DB[arg0].data.shadingTable[2][1] + 1, #(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
    UI.DB[arg0].text
  })):gsub("" .. newLinePrefix, "") or "")
  UI.DB[arg0].data.showtext = table.concat(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
    UI.DB[arg0].text
  }, "\n", UI.DB[arg0].data.line_i, (math.min(#(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
    UI.DB[arg0].text
  }), UI.DB[arg0].data.line_i + math.floor(UI.DB[arg0].dimensions.height / dxGetFontHeight(UI.DB[arg0].font.size, UI.DB[arg0].font.name)) + 1))):gsub("" .. newLinePrefix, "")
  UI.DB[arg0].data.caretLine = UI.DB[arg0].data.shadingTable[1][1]
  UI.DB[arg0].data.caret = UI.DB[arg0].data.shadingTable[1][2] + utfLen(arg1)
  if uiMemoGetCaretIndex(arg0) ~= uiMemoGetCaretIndex(arg0) then
    triggerEvent("onClientUICaretPositionChange", arg0, uiMemoGetCaretIndex(arg0))
  end
  UI.DB[arg0].data.shadingTable = {
    {
      1,
      1,
      1
    },
    {
      1,
      1,
      1
    }
  }
  return true
end
function copyShadedMemoText(arg0, arg1)
  if (getKeyState("lctrl") or getKeyState("rctrl")) and UI.FocusElement and getElementType(UI.FocusElement) == "ui-memo" then
    if string.lower(arg0) == "x" and replaceShadedText(UI.FocusElement, "") then
      triggerEvent("onClientUITextChange", UI.FocusElement)
    end
    setClipboard(utfSub(UI.DB[UI.FocusElement].text, utfLen((table.concat(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      UI.DB[UI.FocusElement].text
    }, "\n", 1, UI.DB[UI.FocusElement].data.shadingTable[1][1] - 1):gsub("" .. newLinePrefix, ""))) + UI.DB[UI.FocusElement].data.shadingTable[1][2], utfLen((table.concat(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      UI.DB[UI.FocusElement].text
    }, "\n", 1, UI.DB[UI.FocusElement].data.shadingTable[2][1] - 1):gsub("" .. newLinePrefix, ""))) + UI.DB[UI.FocusElement].data.shadingTable[2][3] - 1):gsub("\n", "" .. newLinePrefix):gsub("" .. newLinePrefix, "\n"))
  end
end
bindKey("C", "down", copyShadedMemoText)
bindKey("X", "down", copyShadedMemoText)
function MouseWheel(arg0, arg1)
  if not isUIElement(UI.HoveredElement, "memo") then
    return
  end
  if isElement(UI.DB[UI.HoveredElement].data.scrollbar) then
    uiScrollBarSetScrollPosition(UI.DB[UI.HoveredElement].data.scrollbar, (tonumber(UI.DB[UI.DB[UI.HoveredElement].data.scrollbar].data.scroll) or 0) + (arg0 == "mouse_wheel_up" and -1 or 1) * 5)
  end
end
bindKey("mouse_wheel_up", "both", MouseWheel)
bindKey("mouse_wheel_down", "both", MouseWheel)
