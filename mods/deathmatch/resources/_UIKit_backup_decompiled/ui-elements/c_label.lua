-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateLabel(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
  if isUIElement(arg6) then
    arg8 = arg6
    arg7 = nil
    arg6 = nil
  end
  if type(arg4) == "string" then
    arg4 = {en = arg4, ar = arg4}
  end
  arg4.en = formatText(arg4.en)
  arg4.ar = formatText(arg4.ar)
  if type(arg5) == "string" then
    arg5 = theme.COLORS[arg5] or theme.COLORS.primary
  end
  UI.DB[createElement("ui-label")] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = arg4,
    colors = {arg5},
    data = {shakeAnim = false},
    align = {
      X = arg6 or "left",
      Y = arg7 or "top"
    },
    font = {name = dxFont, size = 1},
    animation = {0},
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
      word_break = {value = false, valueType = "boolean"},
      clip = {value = false, valueType = "boolean"},
      color_coded = {value = true, valueType = "boolean"},
      line_spacing = {value = 0, valueType = "number"}
    }
  }
  addUIElement(createElement("ui-label"), arg8, sourceResource)
  return (createElement("ui-label"))
end
function uiLabelApplyShakeAnimation(arg0, arg1)
  assert(isUIElement(arg0, "label"), "Bad argument @ 'uiLabelApplyShakeAnimation' [Expected ui-label at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].data.shakeAnim = true
  UI.DB[arg0].data.shakeColor = arg1 or tocolor(255, 0, 0, 255)
  UI.DB[arg0].animation[1] = getTickCount()
  if isTimer(var0[arg0]) then
    killTimer(var0[arg0])
  end
  var0[arg0] = setTimer(function(arg0)
    UI.DB[arg0].data.shakeAnim = false
  end, 400, 1, arg0)
end
UI.getDrawFunction["ui-label"] = function(arg0)
  UI.HoveredElement = isMouseInPosition(anim(UI.DB[arg0].animation[1], 400, UI.DB[arg0].dimensions.x - 3, 0, 0, 0, UI.DB[arg0].dimensions.x + 3, 0, 0, 0, "OutInBack"), UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height) and arg0 or UI.HoveredElement
  dxDrawText(tostring(UI.DB[arg0].text[language]), anim(UI.DB[arg0].animation[1], 400, UI.DB[arg0].dimensions.x - 3, 0, 0, 0, UI.DB[arg0].dimensions.x + 3, 0, 0, 0, "OutInBack"), UI.DB[arg0].dimensions.y, anim(UI.DB[arg0].animation[1], 400, UI.DB[arg0].dimensions.x - 3, 0, 0, 0, UI.DB[arg0].dimensions.x + 3, 0, 0, 0, "OutInBack") + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].data.shakeColor, UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, UI.DB[arg0].properties.clip.value, UI.DB[arg0].properties.word_break.value, UI.postGUI, UI.DB[arg0].properties.color_coded.value, false, 0, 0, 0, UI.DB[arg0].properties.line_spacing.value * SCALE_Y)
end
