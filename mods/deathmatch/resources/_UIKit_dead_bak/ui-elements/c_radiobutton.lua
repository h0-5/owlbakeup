-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateRadioButton(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
  local element = createElement("ui-radiobutton")
  if type(arg4) == "string" then
    arg4 = {en = arg4, ar = arg4}
  end
  UI.DB[element] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = arg4,
    colors = {
      arg6 or theme.COLORS.primary
    },
    parent = arg7,
    data = {},
    align = {X = "left", Y = "top"},
    animation = {0},
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
      text_color = {
        value = tocolor(255, 255, 255),
        valueType = "number"
      },
      selected_text_color = {
        value = arg6 or theme.COLORS.primary,
        valueType = "number"
      },
      text_colorcoded = {value = false, valueType = "boolean"}
    }
  }
  addUIElement(element, arg7, sourceResource)
  UI.DB[element].animation[1] = arg5 and getTickCount() or 0
  UI.SelectedRadio[getElementParent((element))] = arg5 and element or UI.SelectedRadio[getElementParent((element))]
  return (element)
end
function uiRadioButtonGetSelected(arg0)
  assert(isUIElement(arg0, "radiobutton"), "Bad argument @ 'uiRadioButtonGetSelected' [Expected ui-radiobutton at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.SelectedRadio[getElementParent(arg0)] == arg0
end
function uiRadioButtonSetSelected(arg0, arg1)
  assert(isUIElement(arg0, "radiobutton"), "Bad argument @ 'uiRadioButtonSetSelected' [Expected ui-radiobutton at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "boolean", "Bad argument @ 'uiRadioButtonSetSelected' [Expected number at argument 2, got " .. type(arg1) .. "]")
  if (arg1 and arg0 or UI.SelectedRadio[getElementParent(arg0)] ~= arg0 and UI.SelectedRadio[getElementParent(arg0)]) ~= UI.SelectedRadio[getElementParent(arg0)] then
    if UI.SelectedRadio[getElementParent(arg0)] then
      UI.DB[UI.SelectedRadio[getElementParent(arg0)]].animation[1] = getTickCount()
    end
    UI.DB[arg0].animation[1] = getTickCount()
    UI.SelectedRadio[getElementParent(arg0)] = arg1 and arg0 or UI.SelectedRadio[getElementParent(arg0)] ~= arg0 and UI.SelectedRadio[getElementParent(arg0)]
    return true
  end
  return false
end
UI.getDrawFunction["ui-radiobutton"] = function(arg0)
  UI.HoveredElement = isMouseInPosition(UI.DB[arg0].dimensions.x - 15 * SCALE_Y, UI.DB[arg0].dimensions.y - 7, UI.DB[arg0].dimensions.width + 15 * SCALE_Y, UI.DB[arg0].dimensions.height + 7) and arg0 or UI.HoveredElement
  if UI.SelectedRadio[getElementParent(arg0)] == arg0 then
  else
  end
  dxDrawEmptyLine(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, 15 * SCALE_Y, 15 * SCALE_Y, tocolor(40, 40, 40, 255), 2, UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, 15 * SCALE_Y, 15 * SCALE_Y, tocolor(40, 40, 40, 255), UI.postGUI)
  dxDrawEmptyLine(UI.DB[arg0].dimensions.x + 3, UI.DB[arg0].dimensions.y + 3, 15 * SCALE_Y - 6, 15 * SCALE_Y - 6, tocolor(anim(UI.DB[arg0].animation[1], 250, dxGetColor(UI.DB[arg0].colors[1]))), 2, UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x + 3, UI.DB[arg0].dimensions.y + 3, 15 * SCALE_Y - 6, 15 * SCALE_Y - 6, tocolor(anim(UI.DB[arg0].animation[1], 250, dxGetColor(UI.DB[arg0].colors[1]))), UI.postGUI)
  dxDrawText(tostring(UI.DB[arg0].text[language]), UI.DB[arg0].dimensions.x + 15 * SCALE_Y + 10, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].properties.selected_text_color.value, UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, false, UI.postGUI, UI.DB[arg0].properties.text_colorcoded.value, false)
end
