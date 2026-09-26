-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateImage(arg0, arg1, arg2, arg3, arg4, arg5)
  local element = createElement("ui-image")
  if type(arg4) == "string" and arg4:sub(1, 1) ~= ":" and sourceResource then
    arg4 = ":" .. getResourceName(sourceResource) .. "/" .. arg4
  end
  UI.DB[element] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = text,
    colors = {
      tocolor(255, 255, 255, 255)
    },
    data = {filename = arg4},
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
      rotation = {value = 0, valueType = "number"},
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
  addUIElement(element, arg5, sourceResource)
  return (element)
end
function uiStaticImageLoadImage(arg0, arg1)
  assert(isUIElement(arg0, "image"), "Bad argument @ 'uiGridListSetItemColor' [Expected ui-image at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if type(arg1) == "string" and arg1:sub(1, 1) ~= ":" and sourceResource then
    arg1 = ":" .. getResourceName(sourceResource) .. "/" .. arg1
  end
  UI.DB[arg0].data.filename = arg1
  return true
end
UI.getDrawFunction["ui-image"] = function(arg0)
  if UI.DB[arg0].data.filename then
    hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
    dxDrawImage(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, UI.DB[arg0].data.filename, UI.DB[arg0].properties.rotation.value, 0, 0, tocolor(dxGetColor(UI.DB[arg0].colors[1])), UI.postGUI)
  end
end
