-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateComboBox(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
  local element = createElement("ui-combobox")
  UI.DB[element] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    colors = {arg5},
    text = arg4,
    align = {X = "left", Y = "center"},
    font = {name = dxFont, size = 1},
    data = {
      items = {},
      selected_item = -1,
      visible = false,
      hovered_item = false,
      shown_items = {-1, -1}
    },
    properties = {
      items_per_page = {value = 10, valueType = "number"},
      text_color = {
        value = tocolor(65, 68, 73, 255),
        valueType = "number"
      },
      arrow_color = {
        value = tocolor(142, 149, 165, 255),
        valueType = "number"
      },
      arrow_background_color = {
        value = tocolor(181, 181, 181, 255),
        valueType = "number"
      },
      arrow_hover_background_color = {
        value = tocolor(142, 149, 165, 255),
        valueType = "number"
      },
      arrow_click_background_color = {
        value = tocolor(109, 111, 114, 255),
        valueType = "number"
      },
      arrow_hover_color = {
        value = tocolor(181, 181, 181, 255),
        valueType = "number"
      },
      item_background_color = {
        value = tocolor(65, 68, 73, 255),
        valueType = "number"
      },
      item_hover_background_color = {
        value = tocolor(23, 83, 178, 255),
        valueType = "number"
      },
      item_hover_text_color = {
        value = tocolor(219, 221, 224, 255),
        valueType = "number"
      },
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
  addUIElement(element, arg6, sourceResource)
  UI.DB[element].scrollbar = {
    element = uiCreateScrollBar(arg2 + 5, 0, 10, 150, tocolor(255, 255, 255, 255), tocolor(30, 30, 30, 255), false, (element)),
    related_dimensions = {
      x = 5,
      y = 0,
      width = 10,
      height = 150
    },
    color = tocolor(255, 255, 255, 255),
    background_color = tocolor(30, 30, 30, 255)
  }
  uiSetVisible(UI.DB[element].scrollbar.element, false)
  addEventHandler("onClientUIScroll", UI.DB[element].scrollbar.element, getComboBoxItemsFromScroll)
  return (element)
end
function uiComboBoxAddItem(arg0, arg1, arg2)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxAddItem' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "string", "Bad argument @ 'uiComboBoxAddItem' [Expected string at argument 2, got " .. type(arg1))
  table.insert(UI.DB[arg0].data.items, {
    item_text = arg1,
    item_color = tocolor(255, 255, 255, 255),
    item_height = type(arg2) == "number" and arg2 or 20,
    item_font = {name = dxFont, size = 1},
    item_icon = nil
  })
  uiScrollBarSetScrollPosition(UI.DB[arg0].scrollbar.element, 0)
  UI.DB[arg0].data.shown_items = {
    1,
    math.min(#UI.DB[arg0].data.items, UI.DB[arg0].properties.items_per_page.value)
  }
  uiSetVisible(UI.DB[arg0].scrollbar.element, #UI.DB[arg0].data.items > UI.DB[arg0].properties.items_per_page.value and UI.DB[arg0].data.visible or false)
  return #UI.DB[arg0].data.items - 1
end
function uiComboBoxClear(arg0)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxClear' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].data.items = {}
  UI.DB[arg0].data.selected_item = -1
  UI.DB[arg0].data.shown_items = {-1, -1}
  uiSetVisible(UI.DB[arg0].scrollbar.element, false)
  return true
end
function uiComboBoxGetItemText(arg0, arg1)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxGetItemText' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxGetItemText' [Expected number at argument 2, got " .. type(arg1) .. "]")
  return (UI.DB[arg0].data.items[arg1 + 1] or {item_text = false}).item_text
end
function uiComboBoxGetSelected(arg0)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxGetSelected' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.selected_item
end
function uiComboBoxRemoveItem(arg0, arg1)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxRemoveItem' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1), "Bad argument @ 'uiComboBoxRemoveItem' [Expected number at argument 2, got " .. type(arg1) .. "]")
  if UI.DB[arg0].data.items[arg1 + 1] then
    if UI.DB[arg0].data.selected_item == arg1 then
      UI.DB[arg0].data.selected_item = -1
    end
    table.remove(UI.DB[arg0].data.items, arg1)
    uiScrollBarSetScrollPosition(UI.DB[arg0].scrollbar.element, 0)
    UI.DB[arg0].data.shown_items = {
      1,
      math.min(#UI.DB[arg0].data.items, UI.DB[arg0].properties.items_per_page.value)
    }
    uiSetVisible(UI.DB[arg0].scrollbar.element, #UI.DB[arg0].data.items > UI.DB[arg0].properties.items_per_page.value and UI.DB[arg0].data.visible or false)
    return true
  end
  return false
end
function uiComboBoxSetItemText(arg0, arg1, arg2)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxSetItemText' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1), "Bad argument @ 'uiComboBoxSetItemText' [Expected number at argument 2, got " .. type(arg1) .. "]")
  assert(type(arg2) == "string", "Bad argument @ 'uiComboBoxSetItemText' [Expected string at argument 3, got " .. type(arg2))
  if UI.DB[arg0].data.items[arg1 + 1] then
    UI.DB[arg0].data.items[arg1 + 1].item_text = arg2
    return true
  end
  return false
end
function uiComboBoxSetSelected(arg0, arg1)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxSetSelected' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxSetSelected' [Expected number at argument 2, got " .. type(arg1) .. "]")
  if UI.DB[arg0].data.items[arg1 + 1] then
    UI.DB[arg0].data.selected_item = arg1
    UI.DB[arg0].text = UI.DB[arg0].data.items[arg1 + 1].item_text
    return true
  end
  return false
end
function uiComboBoxSetItemHeight(arg0, arg1, arg2)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxSetItemHeight' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxSetItemHeight' [Expected number at argument 2, got " .. type(arg1) .. "]")
  assert(type(arg2) == "number", "Bad argument @ 'uiComboBoxSetItemHeight' [Expected number at argument 3, got " .. type(arg2) .. "]")
  if UI.DB[arg0].data.items[arg1 + 1] then
    UI.DB[arg0].data.items[arg1 + 1].item_height = arg2
    return true
  end
  return false
end
function uiComboBoxGetItemHeight(arg0, arg1)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxGetItemHeight' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxGetItemHeight' [Expected number at argument 2, got " .. type(arg1) .. "]")
  return (UI.DB[arg0].data.items[arg1 + 1] or {item_height = false}).item_height
end
function uiComboBoxSetItemIcon(arg0, arg1, arg2)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxSetItemIcon' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxSetItemIcon' [Expected number at argument 2, got " .. type(arg1) .. "]")
  assert(type(arg2) == "string" or isElement(arg2) and getElementType(arg2) == "dx-font", "Bad argument @ 'uiComboBoxSetItemIcon' [Expected font at argument 3, got " .. type(arg2) .. "]")
  if UI.DB[arg0].data.items[arg1 + 1] then
    if type(arg2) == "string" and arg2:sub(1, 1) ~= ":" and sourceResource then
      arg2 = ":" .. getResourceName(sourceResource) .. "/" .. arg2
    end
    if fileExists(arg2) then
      UI.DB[arg0].data.items[arg1 + 1].item_icon = {path = arg2, alignX = "left"}
    end
    return true
  end
  return false
end
function uiComboBoxRemoveItemIcon(arg0, arg1)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxRemoveItemIcon' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxRemoveItemIcon' [Expected number at argument 2, got " .. type(arg1) .. "]")
  if UI.DB[arg0].data.items[arg1 + 1] then
    UI.DB[arg0].data.items[arg1 + 1].item_icon = nil
    return true
  end
  return false
end
function uiComboBoxSetItemIconAlignX(arg0, arg1, arg2)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxSetItemIconAlignX' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxSetItemIconAlignX' [Expected number at argument 2, got " .. type(arg1) .. "]")
  assert(arg2 == "left" or arg2 == "right", "Bad argument @ 'uiComboBoxSetItemIconAlignX' [Expected alignX at argument 3, got " .. tostring(arg2) .. "]")
  if UI.DB[arg0].data.items[arg1 + 1] then
    UI.DB[arg0].data.items[arg1 + 1].item_icon.alignX = arg2
    return true
  end
  return false
end
function uiComboBoxGetItemIconAlignX(arg0, arg1)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxGetItemIconAlignX' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxGetItemIconAlignX' [Expected number at argument 2, got " .. type(arg1) .. "]")
  return (UI.DB[arg0].data.items[arg1 + 1] or {
    item_icon = {alignX = false}
  }).item_icon.alignX
end
function uiComboBoxGetItemIcon(arg0, arg1)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxGetItemIcon' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxGetItemIcon' [Expected number at argument 2, got " .. type(arg1) .. "]")
  return (UI.DB[arg0].data.items[arg1 + 1] or {
    item_icon = {path = false}
  }).item_icon.path
end
function uiComboBoxSetItemFont(arg0, arg1, arg2)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxSetItemFont' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if UI.DB[arg0].data.items[arg1 + 1] then
    if type(arg2) ~= "string" and (not isElement(arg2) or getElementType(arg2) ~= "dx-font") or not arg2 then
      arg2 = "default-bold"
    end
    UI.DB[arg0].data.items[arg1 + 1].item_font.name = arg2
    return true
  end
  return false
end
function uiComboBoxSetItemFontSize(arg0, arg1, arg2)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxSetItemFontSize' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if UI.DB[arg0].data.items[arg1 + 1] then
    assert(type(arg2) == "number", "Bad argument @ 'uiComboBoxSetItemFontSize' [Expected number at argument 3, got " .. type(arg2) .. "]")
    UI.DB[arg0].data.items[arg1 + 1].item_font.size = arg2
    return true
  end
  return false
end
function uiComboBoxGetItemFont(arg0, arg1)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxGetItemFont' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxGetItemFont' [Expected number at argument 2, got " .. type(arg1) .. "]")
  return (UI.DB[arg0].data.items[arg1 + 1] or {
    item_font = {name = false}
  }).item_font.name
end
function uiComboBoxGetItemFontSize(arg0, arg1)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxGetItemFontSize' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxGetItemFontSize' [Expected number at argument 2, got " .. type(arg1) .. "]")
  return (UI.DB[arg0].data.items[arg1 + 1] or {
    item_font = {size = false}
  }).item_font.size
end
function uiComboBoxSetScrollBarPosition(arg0, arg1, arg2)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxSetScrollBarPosition' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxSetScrollBarPosition' [Expected number at argument 2, got " .. type(arg1) .. "]")
  assert(type(arg2) == "number", "Bad argument @ 'uiComboBoxSetScrollBarPosition' [Expected number at argument 3, got " .. type(arg2) .. "]")
  UI.DB[arg0].scrollbar.related_dimensions.x, UI.DB[arg0].scrollbar.related_dimensions.y = arg1, arg2
  UI.DB[UI.DB[arg0].scrollbar.element].related_dimensions.x, UI.DB[UI.DB[arg0].scrollbar.element].related_dimensions.y = arg1, arg2
  if isUIElement((getElementParent(arg0))) then
    arg1, arg2 = arg1 + UI.DB[getElementParent(arg0)].dimensions.x, arg2 + UI.DB[getElementParent(arg0)].dimensions.y
  end
  UI.DB[UI.DB[arg0].scrollbar.element].dimensions.x, UI.DB[UI.DB[arg0].scrollbar.element].dimensions.y = arg1, arg2
  return true
end
function uiComboBoxGetScrollBarPosition(arg0)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxGetScrollBarPosition' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].scrollbar.related_dimensions.x, UI.DB[arg0].scrollbar.related_dimensions.y
end
function uiComboBoxSetScrollBarSize(arg0, arg1, arg2)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxSetScrollBarSize' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiComboBoxSetScrollBarPosition' [Expected number at argument 2, got " .. type(arg1) .. "]")
  assert(type(arg2) == "number", "Bad argument @ 'uiComboBoxSetScrollBarPosition' [Expected number at argument 3, got " .. type(arg2) .. "]")
  UI.DB[arg0].scrollbar.related_dimensions.width, UI.DB[arg0].scrollbar.related_dimensions.height = arg1, arg2
  UI.DB[UI.DB[arg0].scrollbar.element].related_dimensions.width, UI.DB[UI.DB[arg0].scrollbar.element].related_dimensions.height = arg1, arg2
  UI.DB[UI.DB[arg0].scrollbar.element].dimensions.width, UI.DB[UI.DB[arg0].scrollbar.element].dimensions.height = arg1, arg2
  return true
end
function uiComboBoxGetScrollBarSize(arg0)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxGetScrollBarSize' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].scrollbar.related_dimensions.width, UI.DB[arg0].scrollbar.related_dimensions.height
end
function uiComboBoxGetItemsCount(arg0)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxGetItemsCount' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return #UI.DB[arg0].data.items
end
function uiComboBoxGetListVisible(arg0)
  assert(isUIElement(arg0, "combobox"), "Bad argument @ 'uiComboBoxGetListVisible' [Expected ui-combobox at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.visible
end
function getComboBoxItemsFromScroll(arg0)
  UI.DB[getElementParent(source)].data.shown_items = {
    math.max(math.floor(#UI.DB[getElementParent(source)].data.items / 100 * arg0), 1),
    (math.min(math.max(math.floor(#UI.DB[getElementParent(source)].data.items / 100 * arg0), 1) + (UI.DB[getElementParent(source)].properties.items_per_page.value - 1), #UI.DB[getElementParent(source)].data.items))
  }
end
UI.getDrawFunction["ui-combobox"] = function(arg0)
  UI.DB[arg0].data.hovered_item = false
  if UI.DB[arg0].data.visible and UI.DB[arg0].data.shown_items[2] > 0 then
    for forvar18 = UI.DB[arg0].data.shown_items[1], UI.DB[arg0].data.shown_items[2] do
      UI.DB[arg0].data.hovered_item = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].dimensions.width, UI.DB[arg0].data.items[forvar18].item_height) and forvar18 - 1 or UI.DB[arg0].data.hovered_item
      if forvar18 == UI.DB[arg0].data.shown_items[2] then
        dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].dimensions.width, UI.DB[arg0].data.items[forvar18].item_height, isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].dimensions.width, UI.DB[arg0].data.items[forvar18].item_height) and UI.DB[arg0].properties.item_hover_background_color.value or UI.DB[arg0].properties.item_background_color.value, 5, {
          up = {left = false, right = false},
          down = {left = true, right = true}
        }, UI.postGUI)
      else
        dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].dimensions.width, UI.DB[arg0].data.items[forvar18].item_height, isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].dimensions.width, UI.DB[arg0].data.items[forvar18].item_height) and UI.DB[arg0].properties.item_hover_background_color.value or UI.DB[arg0].properties.item_background_color.value, UI.postGUI)
      end
      dxDrawText(UI.DB[arg0].data.items[forvar18].item_text, UI.DB[arg0].dimensions.x + 7 + (UI.DB[arg0].data.items[forvar18].item_icon and UI.DB[arg0].data.items[forvar18].item_icon.alignX == "left" and UI.DB[arg0].dimensions.width / 15 + 3 or 0), UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - (UI.DB[arg0].data.items[forvar18].item_icon and UI.DB[arg0].data.items[forvar18].item_icon.alignX == "left" and 0 or UI.DB[arg0].dimensions.width / 15 + 10), UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height + UI.DB[arg0].data.items[forvar18].item_height - (isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].dimensions.width, UI.DB[arg0].data.items[forvar18].item_height) and 2 or 0), isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].dimensions.width, UI.DB[arg0].data.items[forvar18].item_height) and UI.DB[arg0].properties.item_hover_text_color.value or UI.DB[arg0].data.items[forvar18].item_color, UI.DB[arg0].data.items[forvar18].item_font.size, UI.DB[arg0].data.items[forvar18].item_font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, _, UI.postGUI)
      if UI.DB[arg0].data.items[forvar18].item_icon then
        if UI.DB[arg0].data.items[forvar18].item_icon.alignX ~= "left" or not (UI.DB[arg0].dimensions.x + 5) then
        end
        dxDrawImage(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - UI.DB[arg0].dimensions.width / 15 - 5, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height + 5, UI.DB[arg0].dimensions.width / 15, UI.DB[arg0].data.items[forvar18].item_height / 1.5, UI.DB[arg0].data.items[forvar18].item_icon.path, 0, 0, 0, _, UI.postGUI)
      end
      if getKeyState("mouse1") and isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].dimensions.width, UI.DB[arg0].data.items[forvar18].item_height) then
        UI.DB[arg0].data.visible = false
        UI.DB[arg0].data.selected_item = forvar18 - 1
        UI.DB[arg0].text = UI.DB[arg0].data.items[forvar18].item_text
        UI.DB[UI.DB[arg0].scrollbar.element].visible = false
        UI.VisibleList = false
        triggerEvent("onClientUIComboBoxAccepted", arg0, forvar18 - 1)
      end
    end
  end
  UI.HoveredElement = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height + UI.DB[arg0].data.items[forvar18].item_height) and arg0 or UI.HoveredElement
  dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width - UI.DB[arg0].dimensions.width / 8, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].colors[1])), 5, {
    up = {left = true, right = false},
    down = {
      left = not UI.DB[arg0].data.visible or not (UI.DB[arg0].data.shown_items[2] > 0),
      right = false
    }
  }, UI.postGUI)
  dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x + (UI.DB[arg0].dimensions.width - UI.DB[arg0].dimensions.width / 8), UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width / 8, UI.DB[arg0].dimensions.height, getKeyState("mouse1") and UI.DB[arg0].properties.arrow_click_background_color.value or UI.DB[arg0].properties.arrow_hover_background_color.value or UI.DB[arg0].properties.arrow_background_color.value, 5, {
    up = {left = false, right = true},
    down = {
      left = false,
      right = not UI.DB[arg0].data.visible or not (UI.DB[arg0].data.shown_items[2] > 0)
    }
  }, UI.postGUI)
  dxDrawText(UI.DB[arg0].data.visible and "\226\150\178" or "\226\150\188", UI.DB[arg0].dimensions.x + (UI.DB[arg0].dimensions.width - UI.DB[arg0].dimensions.width / 8), UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, isMouseInPosition(UI.DB[arg0].dimensions.x + (UI.DB[arg0].dimensions.width - UI.DB[arg0].dimensions.width / 8), UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width / 8, UI.DB[arg0].dimensions.height) and not isUIDisabled(arg0) and UI.DB[arg0].properties.arrow_hover_color.value or UI.DB[arg0].properties.arrow_color.value, UI.DB[arg0].dimensions.height / 15, UI.DB[arg0].dimensions.height / 15, "default-bold", "center", "center", true, _, UI.postGUI)
  dxDrawText(UI.DB[arg0].text, UI.DB[arg0].dimensions.x + 7, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + (UI.DB[arg0].dimensions.width - UI.DB[arg0].dimensions.width / 8), UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.DB[arg0].properties.text_color.value, UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, _, UI.postGUI)
end
