-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateRectangle(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
  local element = createElement("ui-rectangle")
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
      RoundedOptions = {
        up = {right = arg6, left = arg5},
        down = {right = arg8, left = arg7}
      }
    },
    align = {X = "left", Y = "top"},
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
      border_radius = {value = 7, valueType = "number"},
      postGUI = {
        value = UI.postGUI,
        valueType = "boolean"
      },
      HoverOpacityEffect = {
        value = false,
        valueType = "boolean",
        acceptedValues = {true, false}
      },
      draggable = {
        value = false,
        valueType = "boolean",
        acceptedValues = {true, false}
      }
    }
  }
  addUIElement(element, arg9, sourceResource)
  return (element)
end
UI.getDrawFunction["ui-rectangle"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  if UI.DB[arg0].data.RoundedOptions.up.right or UI.DB[arg0].data.RoundedOptions.up.left or UI.DB[arg0].data.RoundedOptions.down.right or UI.DB[arg0].data.RoundedOptions.down.left then
    dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].colors[1])), UI.DB[arg0].properties.border_radius.value, UI.DB[arg0].data.RoundedOptions, true, UI.DB[arg0].properties.postGUI.value)
  else
    dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].colors[1])), UI.DB[arg0].properties.postGUI.value)
  end
end
