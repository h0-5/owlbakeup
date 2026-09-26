-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateInfoList(arg0, arg1, arg2, arg3, arg4, arg5)
  local element = createElement("ui-infolist")
  arg0 = arg0 or (ref_sx - arg2) / 2
  arg1 = arg1 or (ref_sy - arg3) / 2
  UI.DB[element] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = text,
    colors = {arg4},
    data = {
      rows = {}
    },
    align = {
      X = alignX or "left",
      Y = alignY or "center"
    },
    font = {name = dxFont, size = 1},
    animation = {
      0,
      0,
      false
    },
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
      postGUI = {
        value = UI.postGUI,
        valueType = "boolean"
      },
      icons_color = {
        value = theme.COLORS.primary,
        valueType = "number"
      },
      row_height = {value = 35, valueType = "number"}
    }
  }
  addUIElement(element, arg5, sourceResource)
  return (element)
end
function uiInfoListSetRows(arg0, arg1)
  assert(isUIElement(arg0, "infolist"), "Bad argument @ 'uiInfoListSetRows' [Expected ui-infolist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if arg1 then
    for forvar5, forvar6 in ipairs(arg1) do
      arg1[forvar5].width = dxGetTextWidth(forvar6.text, UI.DB[arg0].font.size, UI.DB[arg0].font.name) + 15 * SCALE_Y
      if forvar6.icon then
        arg1[forvar5].width = arg1[forvar5].width + 30 * SCALE_Y
      end
    end
    UI.DB[arg0].data.rows = arg1
  end
end
function uiInfoListGetRows(arg0)
  assert(isUIElement(arg0, "infolist"), "Bad argument @ 'uiInfoListSetRows' [Expected ui-infolist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.rows
end
function uiInfoListClear(arg0)
  assert(isUIElement(arg0, "infolist"), "Bad argument @ 'uiInfoListClear' [Expected ui-infolist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].data.rows = {}
end
UI.getDrawFunction["ui-infolist"] = function(arg0)
  for forvar15 = 1, #UI.DB[arg0].data.rows do
    dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 5 * SCALE_Y + (30 * SCALE_Y + 4) * (forvar15 - 1), UI.DB[arg0].data.rows[forvar15].width, 30 * SCALE_Y, UI.DB[arg0].colors[1], var0)
    if UI.DB[arg0].data.rows[forvar15].icon then
      dxDrawImage(UI.DB[arg0].dimensions.x + 7 * SCALE_Y, UI.DB[arg0].dimensions.y + 5 * SCALE_Y + (30 * SCALE_Y + 4) * (forvar15 - 1) + (30 * SCALE_Y - 30 * SCALE_Y / 1.7) / 2, 30 * SCALE_Y / 1.7, 30 * SCALE_Y / 1.7, UI.DB[arg0].data.rows[forvar15].icon, 0, 0, 0, UI.DB[arg0].properties.icons_color.value, UI.postGUI)
    end
    dxDrawText(tostring(UI.DB[arg0].data.rows[forvar15].text), UI.DB[arg0].dimensions.x + 7 * SCALE_Y + 30 * SCALE_Y / 1.7 + 10 * SCALE_Y, UI.DB[arg0].dimensions.y + 5 * SCALE_Y + (30 * SCALE_Y + 4) * (forvar15 - 1), UI.DB[arg0].dimensions.x + 7 * SCALE_Y + UI.DB[arg0].data.rows[forvar15].width, UI.DB[arg0].dimensions.y + 5 * SCALE_Y + (30 * SCALE_Y + 4) * (forvar15 - 1) + 30 * SCALE_Y, tocolor(255, 255, 255, 255), 1, UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, false, UI.postGUI, true, false)
  end
end
