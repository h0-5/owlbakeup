-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateContainer(arg0, arg1, arg2, arg3, arg4)
  arg0 = arg0 or (ref_sx - arg2) / 2
  arg1 = arg1 or (ref_sy - arg3) / 2
  UI.DB[createElement("ui-container")] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = text,
    colors = {},
    data = {},
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
      }
    }
  }
  addUIElement(createElement("ui-container"), arg4, sourceResource)
  return (createElement("ui-container"))
end
UI.getDrawFunction["ui-container"] = function(arg0)
end
