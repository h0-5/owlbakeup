-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateRangeSlider(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
  local element = createElement("ui-rangeslider")
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
      arg5,
      arg6 or tocolor(0, 0, 0, 255)
    },
    data = {
      horizontal = arg7,
      value = 0,
      scroll = 0,
      scrollX = 0,
      scrollY = 0,
      clickPositionRelatedToScroll = 0
    },
    font = {name = dxFont, size = 1},
    align = {X = "right", Y = "center"},
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
        value = arg7 and 4 or 4,
        valueType = "number"
      },
      min_value = {value = 0, valueType = "number"},
      max_value = {value = 100, valueType = "number"},
      step_size = {value = 1, valueType = "number"}
    }
  }
  UI.DB[element].data.scrollY = arg1
  UI.DB[element].data.scrollX = arg0
  addUIElement(element, arg8, sourceResource)
  return (element)
end
function uiRangeSliderSetValue(arg0, arg1)
  assert(isUIElement(arg0, "rangeslider"), "Bad argument @ 'uiRangeSliderGetValue' [Expected ui-rangeslider at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
end
function uiRangeSliderGetValue(arg0)
  assert(isUIElement(arg0, "rangeslider"), "Bad argument @ 'uiRangeSliderGetValue' [Expected ui-rangeslider at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.value
end
UI.getDrawFunction["ui-rangeslider"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height / 2 + 5 * SCALE_Y + (UI.DB[arg0].dimensions.height / 2 - 5 * SCALE_Y - (UI.DB[arg0].dimensions.height / 2 - 5 * SCALE_Y) / 2) / 2, UI.DB[arg0].dimensions.width, (UI.DB[arg0].dimensions.height / 2 - 5 * SCALE_Y) / 2, UI.DB[arg0].colors[2], UI.postGUI)
  dxDrawText(UI.DB[arg0].text[language], UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height / 2, tocolor(255, 255, 255), UI.DB[arg0].font.size, UI.DB[arg0].font.name, "left", "center", true, false, UI.postGUI)
  dxDrawText(tostring(UI.DB[arg0].data.value), UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height / 2, tocolor(255, 255, 255), UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, false, UI.postGUI)
  if UI.DB[arg0].data.horizontal then
    dxDrawRectangle(math.max(UI.DB[arg0].data.scrollX, UI.DB[arg0].dimensions.x), UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height / 2 + 5 * SCALE_Y, UI.DB[arg0].properties.thumb_size.value, UI.DB[arg0].dimensions.height / 2 - 5 * SCALE_Y, tocolor(dxGetColor(UI.DB[arg0].colors[1])), UI.postGUI)
    if UI.DB[arg0].state == "clicked" and isCursorShowing() then
      local mcx, mcy = getCursorPosition()
      UI.DB[arg0].data.scrollX = (mcx or 0) * sx - UI.DB[arg0].data.clickPositionRelatedToScroll
      UI.DB[arg0].data.scrollX = math.min(math.max(UI.DB[arg0].dimensions.x + 1, UI.DB[arg0].data.scrollX), UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - UI.DB[arg0].properties.thumb_size.value - 1)
      UI.DB[arg0].data.scroll = math.ceil((UI.DB[arg0].data.scrollX - UI.DB[arg0].dimensions.x - 1) / (UI.DB[arg0].dimensions.width - 2 - UI.DB[arg0].properties.thumb_size.value) * 100)
      if UI.DB[arg0].data.scroll ~= UI.DB[arg0].data.scroll then
        triggerEvent("onClientUIScroll", arg0, UI.DB[arg0].data.scroll)
      end
    end
  else
    dxDrawRectangle(UI.DB[arg0].dimensions.x + 1, UI.DB[arg0].data.scrollY, UI.DB[arg0].dimensions.width - 2, UI.DB[arg0].properties.thumb_size.value, tocolor(dxGetColor(UI.DB[arg0].colors[1])), UI.postGUI)
    if UI.DB[arg0].state == "clicked" and isCursorShowing() then
      local mcx, mcy = getCursorPosition()
      UI.DB[arg0].data.scrollY = (mcy or 0) * sy - UI.DB[arg0].data.clickPositionRelatedToScroll
      UI.DB[arg0].data.scrollY = math.min(math.max(UI.DB[arg0].dimensions.y + 1, UI.DB[arg0].data.scrollY), UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height - UI.DB[arg0].properties.thumb_size.value - 1)
      UI.DB[arg0].data.scroll = math.ceil((UI.DB[arg0].data.scrollY - UI.DB[arg0].dimensions.y - 1) / (UI.DB[arg0].dimensions.height - 2 - UI.DB[arg0].properties.thumb_size.value) * 100)
      if UI.DB[arg0].data.scroll ~= UI.DB[arg0].data.scroll then
        triggerEvent("onClientUIScroll", arg0, UI.DB[arg0].data.scroll)
      end
    end
  end
end
addEventHandler("onClientUIScroll", resourceRoot, function(arg0)
  if getElementType(source) == "ui-rangeslider" then
    UI.DB[source].data.value = getValueByPosition(arg0, UI.DB[source].properties.min_value.value, UI.DB[source].properties.max_value.value, UI.DB[source].properties.step_size.value)
    UI.DB[source].data.scroll = getPositionByValue(UI.DB[source].data.value, UI.DB[source].properties.min_value.value, UI.DB[source].properties.max_value.value, UI.DB[source].properties.step_size.value)
    UI.DB[source].data.scrollX = UI.DB[source].dimensions.x + UI.DB[source].data.scroll * ((UI.DB[source].dimensions.width - UI.DB[source].properties.thumb_size.value) / 100)
  end
end)
function getValueByPosition(arg0, arg1, arg2, arg3)
  return math.floor((arg1 + (arg2 - arg1) * (arg0 / 100)) / arg3) * arg3
end
function getPositionByValue(arg0, arg1, arg2, arg3)
  return (arg0 - arg1) / ((arg2 - arg1) / 100)
end
