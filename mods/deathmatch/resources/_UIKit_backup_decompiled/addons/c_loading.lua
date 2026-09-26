-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateLoading(arg0, arg1, arg2, arg3, arg4, arg5)
  arg0 = arg0 or (ref_sx - arg2) / 2
  arg1 = arg1 or (ref_sy - arg3) / 2
  UI.DB[createElement("ui-loading")] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = text,
    colors = {arg4},
    data = {speed = 1},
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
      }
    }
  }
  addUIElement(createElement("ui-loading"), arg5, sourceResource)
  return (createElement("ui-loading"))
end
UI.getDrawFunction["ui-loading"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  if anim(UI.DB[arg0].animation[1], 500 * UI.DB[arg0].data.speed, 0, 0, 0, 0, 360, 0, 0, 0, "Linear") == 360 then
    UI.DB[arg0].animation[1] = getTickCount()
  end
  dxDrawImage(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, "images/loading.png", anim(UI.DB[arg0].animation[1], 500 * UI.DB[arg0].data.speed, 0, 0, 0, 0, 360, 0, 0, 0, "Linear"), 0, 0, tocolor(dxGetColor(UI.DB[arg0].colors[1])), UI.DB[arg0].properties.postGUI.value)
end
