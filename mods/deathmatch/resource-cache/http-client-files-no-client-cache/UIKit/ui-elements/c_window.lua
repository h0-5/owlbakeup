-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateWindow(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
  local element = createElement("ui-window")
  arg3 = arg3 + 30
  arg0 = arg0 or (ref_sx - arg2) / 2
  arg1 = arg1 or (ref_sy - arg3) / 2
  if type(arg4) == "string" then
    arg4 = {en = arg4, ar = arg4}
  end
  if type(arg6) == "string" and arg6:sub(1, 1) ~= ":" and sourceResource then
    arg6 = ":" .. getResourceName(sourceResource) .. "/" .. arg6
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
      arg5 or theme.COLORS.bg_default
    },
    data = {icon = arg6},
    font = {name = dxFontLarge, size = 1},
    align = {X = "left", Y = "center"},
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
      topline_color = {
        value = theme.COLORS.primary,
        valueType = "number"
      },
      topline_width = {value = 2, valueType = "number"},
      tob_bar_color = {
        value = tocolor(50, 50, 50, 255),
        valueType = "number"
      },
      top_bar_height = {value = 30, valueType = "number"},
      closable = {value = true, valueType = "boolean"},
      movable = {value = true, valueType = "boolean"},
      close_button = {value = false, valueType = "boolean"}
    },
    padding = {
      top = 30,
      right = 0,
      bottom = 0,
      left = 0
    }
  }
  addUIElement(element, nil, sourceResource)
  return (element)
end
function uiWindowSetTitleBarHeight(arg0, arg1)
  assert(isUIElement(arg0, "window"), "Bad argument @ 'uiWindowSetTitleBarHeights' [Expected ui-window at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].properties.top_bar_height.value = arg1 or 20
  return true
end
function uiWindowGetTitleBarHeight(arg0)
  assert(isUIElement(arg0, "window"), "Bad argument @ 'uiWindowGetTitleBarHeight' [Expected ui-window at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].properties.top_bar_height.value
end
function uiWindowSetMovable(arg0, arg1)
  assert(isUIElement(arg0, "window"), "Bad argument @ 'uiWindowSetMovable' [Expected ui-window at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "boolean", "Bad argument @ 'uiWindowSetMovable' [Expected number at argument 2, got " .. type(arg1) .. "]")
  UI.DB[arg0].properties.movable.value = arg1
  return true
end
UI.getDrawFunction["ui-window"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].properties.top_bar_height.value * SCALE_Y + 8 * SCALE_Y)
  dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, UI.DB[arg0].colors[1], 8 * SCALE_Y, _, UI.postGUI)
  dxDrawImage(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 * SCALE_Y + 5 * SCALE_Y, UI.DB[arg0].dimensions.width - 100, UI.DB[arg0].properties.top_bar_height.value * SCALE_Y, getUIImage("gradient_x"), 180, 0, 0, UI.DB[arg0].colors[1], UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 * SCALE_Y + 5 * SCALE_Y, 5, UI.DB[arg0].properties.top_bar_height.value * SCALE_Y, UI.DB[arg0].properties.topline_color.value, UI.postGUI)
  if UI.DB[arg0].data.icon then
    dxDrawImage(UI.DB[arg0].dimensions.x + 20, UI.DB[arg0].dimensions.y + 8 * SCALE_Y + 5 * SCALE_Y + (UI.DB[arg0].properties.top_bar_height.value * SCALE_Y - UI.DB[arg0].properties.top_bar_height.value * SCALE_Y * 0.7) / 2, UI.DB[arg0].properties.top_bar_height.value * SCALE_Y * 0.7, UI.DB[arg0].properties.top_bar_height.value * SCALE_Y * 0.7, UI.DB[arg0].data.icon, 0, 0, 0, tocolor(255, 255, 255, 150), UI.postGUI)
  end
  dxDrawText(UI.DB[arg0].text[language], UI.DB[arg0].dimensions.x + 20 + UI.DB[arg0].properties.top_bar_height.value * SCALE_Y * 0.7 + 15, UI.DB[arg0].dimensions.y + 8 * SCALE_Y + 5 * SCALE_Y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 15, UI.DB[arg0].dimensions.y + 8 * SCALE_Y + 5 * SCALE_Y + UI.DB[arg0].properties.top_bar_height.value * SCALE_Y, tocolor(255, 255, 255, 255), UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, _, UI.postGUI)
  if not isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 28 * SCALE_Y - 8 * SCALE_Y, UI.DB[arg0].dimensions.y + 8 * SCALE_Y + 5 * SCALE_Y + 10 * SCALE_Y - 8 * SCALE_Y, 8 * SCALE_Y * 2, 8 * SCALE_Y * 2) or not tocolor(255, 0, 0) then
  end
  dxDrawCircle(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 28 * SCALE_Y, UI.DB[arg0].dimensions.y + 8 * SCALE_Y + 5 * SCALE_Y + 10 * SCALE_Y, 8 * SCALE_Y, 0, 360, tocolor(20, 20, 20), _, 32, 1, UI.postGUI)
  if isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 28 * SCALE_Y - 8 * SCALE_Y, UI.DB[arg0].dimensions.y + 8 * SCALE_Y + 5 * SCALE_Y + 10 * SCALE_Y - 8 * SCALE_Y, 8 * SCALE_Y * 2, 8 * SCALE_Y * 2) and getKeyState("mouse1") then
    uiSetVisible(arg0, false)
  end
end
