-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateProgressBar(arg0, arg1, arg2, arg3, arg4, arg5)
  UI.DB[createElement("ui-progressbar")] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = {text},
    colors = {
      arg4 or theme.COLORS.primary
    },
    data = {progress = 0},
    animation = {
      0,
      0,
      false
    },
    font = {name = dxFont, size = 1},
    align = {X = "center", Y = "center"},
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
      background_color = {
        value = tocolor(90, 90, 90),
        valueType = "number"
      },
      progress_animation = {value = false, valueType = "boolean"},
      show_progress = {value = true, valueType = "boolean"},
      progress_type = {
        value = "horizontal",
        valueType = "string",
        acceptedValues = {
          "horizontal",
          "vertical",
          "circular"
        }
      },
      progress_color = {
        value = theme.COLORS.primary,
        valueType = "number"
      }
    }
  }
  addUIElement(createElement("ui-progressbar"), arg5, sourceResource)
  return (createElement("ui-progressbar"))
end
function uiProgressBarSetProgress(arg0, arg1)
  assert(isUIElement(arg0, "progressbar"), "Bad argument @ 'uiProgressBarSetProgress' [Expected ui-progressbar at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if UI.DB[arg0].data.progress ~= arg1 then
    UI.DB[arg0].data.progress = arg1
    if not UI.DB[arg0].animation[3] and UI.DB[arg0].properties.progress_animation.value then
      UI.DB[arg0].animation = {
        getTickCount(),
        UI.DB[arg0].data.progress,
        true
      }
    end
    triggerEvent("onClientUIProgressBarChange", arg0, UI.DB[arg0].data.progress)
    return true
  end
  return false
end
function uiProgressBarGetProgress(arg0)
  assert(isUIElement(arg0, "progressbar"), "Bad argument @ 'uiProgressBarGetProgress' [Expected ui-progressbar at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.progress
end
UI.getDrawFunction["ui-progressbar"] = function(arg0)
  if anim(UI.DB[arg0].animation[1], 1000, UI.DB[arg0].animation[2], 0, 0, 0, UI.DB[arg0].data.progress, 0, 0, 0, "Linear") == UI.DB[arg0].data.progress and UI.DB[arg0].animation[3] then
    UI.DB[arg0].animation[3] = false
  end
  if UI.DB[arg0].properties.progress_type.value == "horizontal" then
    dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].properties.background_color.value)), UI.postGUI)
    dxDrawEmptyLine(UI.DB[arg0].dimensions.x - 1, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].properties.background_color.value)), 2, UI.postGUI)
    if UI.DB[arg0].animation[3] then
      dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width / 100 * UI.DB[arg0].animation[2], UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].colors[1])), UI.postGUI)
      dxDrawEmptyLine(UI.DB[arg0].dimensions.x - 1, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width / 100 * UI.DB[arg0].animation[2], UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].colors[1])), 2, UI.postGUI)
    end
    dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width / 100 * anim(UI.DB[arg0].animation[1], 1000, UI.DB[arg0].animation[2], 0, 0, 0, UI.DB[arg0].data.progress, 0, 0, 0, "Linear"), UI.DB[arg0].dimensions.height, UI.DB[arg0].colors[1], UI.postGUI)
    dxDrawEmptyLine(UI.DB[arg0].dimensions.x - 1, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width / 100 * anim(UI.DB[arg0].animation[1], 1000, UI.DB[arg0].animation[2], 0, 0, 0, UI.DB[arg0].data.progress, 0, 0, 0, "Linear"), UI.DB[arg0].dimensions.height, UI.DB[arg0].colors[1], 2, UI.postGUI)
  elseif UI.DB[arg0].properties.progress_type.value == "vertical" then
    dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].properties.background_color.value)), UI.postGUI)
    dxDrawEmptyLine(UI.DB[arg0].dimensions.x - 1, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].properties.background_color.value)), 2, UI.postGUI)
    if UI.DB[arg0].animation[3] then
      dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - UI.DB[arg0].dimensions.height / 100 * UI.DB[arg0].animation[2], UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height / 100 * UI.DB[arg0].animation[2], tocolor(dxGetColor(UI.DB[arg0].colors[1])), UI.postGUI)
      dxDrawEmptyLine(UI.DB[arg0].dimensions.x - 1, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - UI.DB[arg0].dimensions.height / 100 * UI.DB[arg0].animation[2], UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height / 100 * UI.DB[arg0].animation[2], tocolor(dxGetColor(UI.DB[arg0].colors[1])), 2, UI.postGUI)
    end
    dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - UI.DB[arg0].dimensions.height / 100 * anim(UI.DB[arg0].animation[1], 1000, UI.DB[arg0].animation[2], 0, 0, 0, UI.DB[arg0].data.progress, 0, 0, 0, "Linear"), UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height / 100 * anim(UI.DB[arg0].animation[1], 1000, UI.DB[arg0].animation[2], 0, 0, 0, UI.DB[arg0].data.progress, 0, 0, 0, "Linear"), UI.DB[arg0].colors[1], UI.postGUI)
    dxDrawEmptyLine(UI.DB[arg0].dimensions.x - 1, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - UI.DB[arg0].dimensions.height / 100 * anim(UI.DB[arg0].animation[1], 1000, UI.DB[arg0].animation[2], 0, 0, 0, UI.DB[arg0].data.progress, 0, 0, 0, "Linear"), UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height / 100 * anim(UI.DB[arg0].animation[1], 1000, UI.DB[arg0].animation[2], 0, 0, 0, UI.DB[arg0].data.progress, 0, 0, 0, "Linear"), UI.DB[arg0].colors[1], 2, UI.postGUI)
  elseif UI.DB[arg0].properties.progress_type.value == "circular" then
    dxDrawCircle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, (UI.DB[arg0].dimensions.width + UI.DB[arg0].dimensions.height) / 2 + 2, 0, anim(UI.DB[arg0].animation[1], 1000, UI.DB[arg0].animation[2], 0, 0, 0, UI.DB[arg0].data.progress, 0, 0, 0, "Linear") * 3.6, tocolor(dxGetColor(UI.DB[arg0].colors[1])), tocolor(dxGetColor(UI.DB[arg0].colors[1])), _, _, UI.postGUI)
    dxDrawCircle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, (UI.DB[arg0].dimensions.width + UI.DB[arg0].dimensions.height) / 2, 0, 360, tocolor(dxGetColor(UI.DB[arg0].properties.background_color.value)), tocolor(dxGetColor(UI.DB[arg0].properties.background_color.value)), _, _, UI.postGUI)
  end
  if UI.DB[arg0].properties.show_progress.value then
    if UI.DB[arg0].properties.progress_type.value ~= "circular" then
      dxDrawText(math.floor((anim(UI.DB[arg0].animation[1], 1000, UI.DB[arg0].animation[2], 0, 0, 0, UI.DB[arg0].data.progress, 0, 0, 0, "Linear"))) .. "%", UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].properties.progress_color.value, 1, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, _, UI.postGUI)
    else
      dxDrawText(math.floor((anim(UI.DB[arg0].animation[1], 1000, UI.DB[arg0].animation[2], 0, 0, 0, UI.DB[arg0].data.progress, 0, 0, 0, "Linear"))) .. "%", UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + 2, UI.DB[arg0].dimensions.y, UI.DB[arg0].properties.progress_color.value, 1, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, _, _, UI.postGUI)
    end
  end
end
