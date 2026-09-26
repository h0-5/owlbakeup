-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateScrollBar(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
  local element = createElement("ui-scrollbar")
  UI.DB[element] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = {text},
    colors = {
      arg4,
      arg5 or tocolor(0, 0, 0, 255)
    },
    data = {
      horizontal = arg6,
      scroll = 0,
      scrollX = 0,
      scrollY = 0,
      clickPositionRelatedToScroll = 0
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
      thumb_size = {
        value = arg6 and arg2 / 4 or arg3 / 4,
        valueType = "number"
      }
    }
  }
  UI.DB[element].data.scrollY = arg1 + 1
  UI.DB[element].data.scrollX = arg0 + 1
  addUIElement(element, arg7, sourceResource)
  return (element)
end
function uiScrollBarSetScrollPosition(arg0, arg1)
  assert(isUIElement(arg0, "scrollbar"), "Bad argument @ 'uiScrollBarSetScrollPosition' [Expected ui-scrollbar at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiScrollBarSetScrollPosition' [Expected number at argument 2, got " .. type(arg1) .. "]")
  arg1 = math.floor(math.min(math.max(0, arg1), 100))
  if UI.DB[arg0].data.horizontal then
    UI.DB[arg0].data.scrollX = (arg1 * (UI.DB[arg0].dimensions.width - 2 - UI.DB[arg0].properties.thumb_size.value) + 100 * UI.DB[arg0].dimensions.x + 100) / 100
  else
    UI.DB[arg0].data.scrollY = (arg1 * (UI.DB[arg0].dimensions.height - 2 - UI.DB[arg0].properties.thumb_size.value) + 100 * UI.DB[arg0].dimensions.y + 100) / 100
  end
  if arg1 ~= UI.DB[arg0].data.scroll then
    UI.DB[arg0].data.scroll = arg1
    triggerEvent("onClientUIScroll", arg0, arg1)
  end
end
function uiScrollBarGetScrollPosition(arg0)
  assert(isUIElement(arg0, "scrollbar"), "Bad argument @ 'uiScrollBarGetScrollPosition' [Expected ui-scrollbar at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.scroll
end
UI.getDrawFunction["ui-scrollbar"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, UI.DB[arg0].colors[2], UI.postGUI)
  dxDrawEmptyLine(UI.DB[arg0].dimensions.x - 1, UI.DB[arg0].dimensions.y - 1, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, UI.DB[arg0].colors[2], 2, UI.postGUI)
  if UI.DB[arg0].data.horizontal then
    dxDrawRectangle(UI.DB[arg0].data.scrollX, UI.DB[arg0].dimensions.y + 1, UI.DB[arg0].properties.thumb_size.value, UI.DB[arg0].dimensions.height - 2, tocolor(dxGetColor(UI.DB[arg0].colors[1])), UI.postGUI)
    if UI.DB[arg0].state == "clicked" and isCursorShowing() then
      UI.DB[arg0].data.scrollX = getCursorPosition() * sx - UI.DB[arg0].data.clickPositionRelatedToScroll
      UI.DB[arg0].data.scrollX = math.min(math.max(UI.DB[arg0].dimensions.x + 1, UI.DB[arg0].data.scrollX), UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - UI.DB[arg0].properties.thumb_size.value - 1)
      UI.DB[arg0].data.scroll = math.ceil((UI.DB[arg0].data.scrollX - UI.DB[arg0].dimensions.x - 1) / (UI.DB[arg0].dimensions.width - 2 - UI.DB[arg0].properties.thumb_size.value) * 100)
      if UI.DB[arg0].data.scroll ~= UI.DB[arg0].data.scroll then
        triggerEvent("onClientUIScroll", arg0, UI.DB[arg0].data.scroll)
      end
    end
  else
    dxDrawRectangle(UI.DB[arg0].dimensions.x + 1, UI.DB[arg0].data.scrollY, UI.DB[arg0].dimensions.width - 2, UI.DB[arg0].properties.thumb_size.value, tocolor(dxGetColor(UI.DB[arg0].colors[1])), UI.postGUI)
    if UI.DB[arg0].state == "clicked" and isCursorShowing() then
      UI.DB[arg0].data.scrollY = getCursorPosition() * sy - UI.DB[arg0].data.clickPositionRelatedToScroll
      UI.DB[arg0].data.scrollY = math.min(math.max(UI.DB[arg0].dimensions.y + 1, UI.DB[arg0].data.scrollY), UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - UI.DB[arg0].properties.thumb_size.value - 1)
      UI.DB[arg0].data.scroll = math.ceil((UI.DB[arg0].data.scrollY - UI.DB[arg0].dimensions.y - 1) / (UI.DB[arg0].dimensions.height - 2 - UI.DB[arg0].properties.thumb_size.value) * 100)
      if UI.DB[arg0].data.scroll ~= UI.DB[arg0].data.scroll then
        triggerEvent("onClientUIScroll", arg0, UI.DB[arg0].data.scroll)
      end
    end
  end
end
function MouseWheel(arg0, arg1)
  if not isUIElement(UI.HoveredElement, "scrollbar") then
    return
  end
  uiScrollBarSetScrollPosition(UI.HoveredElement, (tonumber(UI.DB[UI.HoveredElement].data.scroll) or 0) + (arg0 == "mouse_wheel_up" and -1 or 1) * 5)
end
bindKey("mouse_wheel_up", "both", MouseWheel)
bindKey("mouse_wheel_down", "both", MouseWheel)
