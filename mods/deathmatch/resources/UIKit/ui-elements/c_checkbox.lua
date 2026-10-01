-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateSwitch(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
  local element = createElement("ui-switch")
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
    data = {selected = arg5},
    align = {X = "left", Y = "center"},
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
      color_coded = {value = true, valueType = "boolean"}
    }
  }
  addUIElement(element, arg7, sourceResource)
  return (element)
end
function uiSwitchGetSelected(arg0)
  assert(isUIElement(arg0, "switch"), "Bad argument @ 'uiSwitchGetSelected' [Expected ui-switch at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.selected
end
function uiSwitchSetSelected(arg0, arg1)
  assert(isUIElement(arg0, "switch"), "Bad argument @ 'uiSwitchSetSelected' [Expected ui-switch at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "boolean", "Bad argument @ 'uiSwitchSetSelected' [Expected number at argument 2, got " .. type(arg1) .. "]")
  UI.DB[arg0].data.selected = arg1
  return true
end
UI.getDrawFunction["ui-switch"] = function(arg0)
  UI.HoveredElement = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, 30 * SCALE_Y, UI.DB[arg0].dimensions.height) and arg0 or UI.HoveredElement
  if UI.DB[arg0].data.selected then
  else
  end
  dxDrawEmptyLine(UI.DB[arg0].dimensions.x - 1, UI.DB[arg0].dimensions.y, 30 * SCALE_Y + 1, 15 * SCALE_Y, tocolor(40, 40, 40, 255), 2, UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, 30 * SCALE_Y, 15 * SCALE_Y, tocolor(40, 40, 40, 255), UI.postGUI)
  dxDrawEmptyLine(UI.DB[arg0].data.selected and anim(UI.DB[arg0].animation[1], 250, UI.DB[arg0].dimensions.x + 30 * SCALE_Y - 2 - (15 * SCALE_Y - 4), UI.DB[arg0].dimensions.x + 2, 0, 0, UI.DB[arg0].dimensions.x + 2, UI.DB[arg0].dimensions.x + 30 * SCALE_Y - 2 - (15 * SCALE_Y - 4), 0, 0, "Linear") - 1 or anim(UI.DB[arg0].animation[1], 250, UI.DB[arg0].dimensions.x + 30 * SCALE_Y - 2 - (15 * SCALE_Y - 4), UI.DB[arg0].dimensions.x + 2, 0, 0, UI.DB[arg0].dimensions.x + 2, UI.DB[arg0].dimensions.x + 30 * SCALE_Y - 2 - (15 * SCALE_Y - 4), 0, 0, "Linear") - 1, UI.DB[arg0].dimensions.y + 2, 15 * SCALE_Y - 4 + 1, 15 * SCALE_Y - 4, tocolor(anim(UI.DB[arg0].animation[1], 250, dxGetColor(UI.DB[arg0].colors[1]))), 2, UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].data.selected and anim(UI.DB[arg0].animation[1], 250, UI.DB[arg0].dimensions.x + 30 * SCALE_Y - 2 - (15 * SCALE_Y - 4), UI.DB[arg0].dimensions.x + 2, 0, 0, UI.DB[arg0].dimensions.x + 2, UI.DB[arg0].dimensions.x + 30 * SCALE_Y - 2 - (15 * SCALE_Y - 4), 0, 0, "Linear") or anim(UI.DB[arg0].animation[1], 250, UI.DB[arg0].dimensions.x + 30 * SCALE_Y - 2 - (15 * SCALE_Y - 4), UI.DB[arg0].dimensions.x + 2, 0, 0, UI.DB[arg0].dimensions.x + 2, UI.DB[arg0].dimensions.x + 30 * SCALE_Y - 2 - (15 * SCALE_Y - 4), 0, 0, "Linear"), UI.DB[arg0].dimensions.y + 2, 15 * SCALE_Y - 4 + 1, 15 * SCALE_Y - 4, tocolor(anim(UI.DB[arg0].animation[1], 250, dxGetColor(UI.DB[arg0].colors[1]))), UI.postGUI)
  dxDrawText(tostring(UI.DB[arg0].text[language]), UI.DB[arg0].dimensions.x + 30 * SCALE_Y + 10, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, tocolor(255, 255, 255, 255), 1, UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, false, UI.postGUI, UI.DB[arg0].properties.color_coded.value, false)
end
function uiCreateCheckBox(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
  local element = createElement("ui-checkbox")
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
    data = {selected = arg5},
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
      color_coded = {value = true, valueType = "boolean"}
    }
  }
  addUIElement(element, arg7, sourceResource)
  return (element)
end
function uiCheckBoxGetSelected(arg0)
  assert(isUIElement(arg0, "checkbox"), "Bad argument @ 'uiCheckBoxGetSelected' [Expected ui-checkbox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.selected
end
function uiCheckBoxSetSelected(arg0, arg1)
  assert(isUIElement(arg0, "checkbox"), "Bad argument @ 'uiCheckBoxSetSelected' [Expected ui-checkbox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "boolean", "Bad argument @ 'uiCheckBoxSetSelected' [Expected number at argument 2, got " .. type(arg1) .. "]")
  UI.DB[arg0].data.selected = arg1
  return true
end
UI.getDrawFunction["ui-checkbox"] = function(arg0)
  UI.HoveredElement = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height) and arg0 or UI.HoveredElement
  if UI.DB[arg0].data.selected then
  else
  end
  dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, 15, 15, tocolor(60, 60, 60, 255), UI.postGUI)
  -- [Vortex fix] the old fill was tocolor(anim(t, 500, dxGetColor(...))):
  -- anim() with only a START color returns nils once "done", so tocolor got
  -- nil and the inner fill drew fully transparent (empty-looking box).
  local cr, cg, cb, ca = dxGetColor(UI.DB[arg0].colors[1])
  dxDrawRectangle(UI.DB[arg0].dimensions.x + 2, UI.DB[arg0].dimensions.y + 2, 15 - 4, 15 - 4, tocolor(cr, cg, cb, ca), UI.postGUI)
  if UI.DB[arg0].data.selected then
    dxDrawLine(UI.DB[arg0].dimensions.x + 4, UI.DB[arg0].dimensions.y + 6, UI.DB[arg0].dimensions.x + 4, UI.DB[arg0].dimensions.y + 15 - 5, tocolor(255, 255, 255, 255), 1, UI.postGUI)
    dxDrawLine(UI.DB[arg0].dimensions.x + 4, UI.DB[arg0].dimensions.y + 15 - 5, UI.DB[arg0].dimensions.x + 11, UI.DB[arg0].dimensions.y + 3, tocolor(255, 255, 255, 255), 1, UI.postGUI)
  end
  dxDrawText(tostring(UI.DB[arg0].text[language]), UI.DB[arg0].dimensions.x + 15 + 5, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, tocolor(255, 255, 255, 255), 1, UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, false, UI.postGUI, UI.DB[arg0].properties.color_coded.value, false)
end
