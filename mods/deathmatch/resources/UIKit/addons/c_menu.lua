-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateMenu(arg0, arg1, arg2, arg3, arg4, arg5)
  local element = createElement("ui-menu")
  UI.DB[element] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    colors = {arg4},
    data = {
      rows = {},
      row_i = 1,
      row_f = 1,
      selected_row = -1,
      hovered_row = false
    },
    align = {
      X = alignX or "left",
      Y = alignY or "center"
    },
    font = {name = dxFont, size = 1},
    animation = {0},
    properties = {
      row_font_scale = {value = 1, valueType = "number"},
      row_height = {value = 35, valueType = "number"},
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
      selection_color = {
        value = theme.COLORS.primary,
        valueType = "number"
      },
      selected_row_color = {
        value = tocolor(29, 32, 37),
        valueType = "number"
      },
      hovered_row_color = {
        value = tocolor(39, 42, 47),
        valueType = "number"
      },
      icons_color = {
        value = tocolor(255, 255, 255, 200),
        valueType = "number"
      }
    }
  }
  addUIElement(element, arg5, sourceResource)
  UI.DB[element].data.scrollbar = uiCreateScrollBar(arg2 - 10, 3, 9, arg3 - 5, tocolor(204, 199, 199), tocolor(255, 255, 255, 0), false, element, tocolor(0, 0, 0, 0))
  uiSetVisible(UI.DB[element].data.scrollbar, false)
  return (element)
end
function calcCLRowsHeight(arg0)
  local rows = UI.DB[arg0].data.rows or {}
  local last = rows[#rows]
  if not last then return 0 end
  return 2 + last.height + 4
end
function findLastCLRow(arg0)
  for forvar5 = UI.DB[arg0].data.row_i, #UI.DB[arg0].data.rows do
    if 2 + UI.DB[arg0].data.rows[forvar5].height + 4 > UI.DB[arg0].dimensions.height then
      return forvar5 - 1
    end
  end
  return #UI.DB[arg0].data.rows
end
function uiMenuAddRow(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
  assert(isUIElement(arg0, "menu"), "Bad argument @ 'uiMenuAddRow' [Expected ui-menu at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if arg3 and type(arg3) == "string" and arg3:sub(1, 1) ~= ":" and sourceResource then
    arg3 = ":" .. getResourceName(sourceResource) .. "/" .. arg3
  end
  if type(arg1) == "string" then
    arg1 = {en = arg1, ar = arg1}
  end
  table.insert(UI.DB[arg0].data.rows, {
    id = arg5,
    text = arg1,
    height = math.min(math.max(UI.DB[arg0].dimensions.height - 2, 0), UI.DB[arg0].properties.row_height.value * SCALE_Y),
    alignX = "left",
    color = arg2 or theme.COLORS.primary,
    icon = arg3,
    emoji = arg6,
    toggle_element = arg4 or false,
    animation = {0}
  })
  if UI.DB[arg0].data.selected_row == -1 then
    UI.DB[arg0].data.selected_row = 1
    if arg4 then
      uiSetVisible(arg4, true)
    end
  end
  if doesChecklistNeedScrollBar(arg0) then
    if not uiGetVisible(UI.DB[arg0].data.scrollbar) then
      uiSetVisible(UI.DB[arg0].data.scrollbar, true)
      addEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollMenu)
    end
  elseif uiGetVisible(UI.DB[arg0].data.scrollbar) then
    removeEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollMenu)
    uiSetVisible(UI.DB[arg0].data.scrollbar, false)
    scrollMenu(0, arg0)
  end
  UI.DB[arg0].data.row_f = findLastCLRow(arg0)
  return #UI.DB[arg0].data.rows
end
function scrollMenu(arg0, arg1)
  if not isUIElement(arg1 or getElementParent(source), "menu") then
    return
  end
  for forvar8 = 1, #UI.DB[arg1 or getElementParent(source)].data.rows do
    if calcCLRowsHeight(arg1 or getElementParent(source)) / 100 * arg0 <= 2 + UI.DB[arg1 or getElementParent(source)].data.rows[forvar8].height * (forvar8 - 1) then
      UI.DB[arg1 or getElementParent(source)].data.row_i = forvar8
      break
    end
  end
  UI.DB[arg1 or getElementParent(source)].data.row_f = findLastCLRow(arg1 or getElementParent(source))
end
function doesChecklistNeedScrollBar(arg0)
  return calcCLRowsHeight(arg0) > UI.DB[arg0].dimensions.height
end
function uiMenuRemoveRow(arg0, arg1)
  assert(isUIElement(arg0, "menu"), "Bad argument @ 'uiMenuRemoveRow' [Expected ui-menu at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1], "Bad argument @ 'uiMenuRemoveRow' [There's no such row index]")
  table.remove(UI.DB[arg0].data.rows, arg1)
  if doesChecklistNeedScrollBar(arg0) then
    if not uiGetVisible(UI.DB[arg0].data.scrollbar) then
      uiSetVisible(UI.DB[arg0].data.scrollbar, true)
      addEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollMenu)
    end
  elseif uiGetVisible(UI.DB[arg0].data.scrollbar) then
    removeEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollMenu)
    uiSetVisible(UI.DB[arg0].data.scrollbar, false)
    scrollMenu(0, arg0)
  end
  UI.DB[arg0].data.row_f = findLastCLRow(arg0)
  return true
end
function uiMenuClear(arg0)
  assert(isUIElement(arg0, "menu"), "Bad argument @ 'uiMenuClear' [Expected ui-menu at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].data.rows = {}
  scrollMenu(0, arg0)
  return true
end
function uiMenuGetRowCount(arg0)
  assert(isUIElement(arg0, "menu"), "Bad argument @ 'uiMenuGetRowCount' [Expected ui-menu at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return #UI.DB[arg0].data.rows
end
function uiMenuGetSelectedRow(arg0)
  assert(isUIElement(arg0, "menu"), "Bad argument @ 'uiMenuSetSelectedRow' [Expected ui-menu at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[row], "Bad argument @ 'uiMenuSetSelectedRow' [There's no such row index]")
  return UI.DB[arg0].data.selected_row
end
function uiMenuSetSelectedRow(arg0, arg1)
  assert(isUIElement(arg0, "menu"), "Bad argument @ 'uiMenuSetSelectedRow' [Expected ui-menu at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1], "Bad argument @ 'uiMenuSetSelectedRow' [There's no such row index]")
  if UI.DB[arg0].data.selected_row ~= arg1 then
    UI.DB[arg0].data.selected_row = arg1
    if UI.DB[arg0].data.rows[UI.DB[arg0].data.selected_row] and UI.DB[arg0].data.rows[UI.DB[arg0].data.selected_row].toggle_element then
      uiSetVisible(UI.DB[arg0].data.rows[UI.DB[arg0].data.selected_row] and UI.DB[arg0].data.rows[UI.DB[arg0].data.selected_row].toggle_element, false)
    end
    if UI.DB[arg0].data.rows[arg1] and UI.DB[arg0].data.rows[arg1].toggle_element then
      uiSetVisible(UI.DB[arg0].data.rows[arg1] and UI.DB[arg0].data.rows[arg1].toggle_element, true)
    end
    triggerEvent("onClientUIMenuSelectChange", arg0, arg1, UI.DB[arg0].data.rows[arg1] and UI.DB[arg0].data.rows[arg1].toggle_element)
  end
  return true
end
function uiMenuGetSelectedItems(arg0)
  assert(isUIElement(arg0, "menu"), "Bad argument @ 'uiMenuGetSelectedItems' [Expected ui-menu at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  for forvar5, forvar6 in ipairs(UI.DB[arg0].data.rows) do
    if forvar6.selected then
      table.insert({}, forvar5)
    end
  end
  return {}
end
function uiMenuGetItemText(arg0, arg1)
  assert(isUIElement(arg0, "menu"), "Bad argument @ 'uiMenuGetItemText' [Expected ui-menu at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1], "Bad argument @ 'uiMenuGetItemText' [There's no such row index]")
  return UI.DB[arg0].data.rows[arg1].text.en
end
function uiMenuSetItemText(arg0, arg1, arg2)
  assert(isUIElement(arg0, "menu"), "Bad argument @ 'uiMenuSetItemText' [Expected ui-menu at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1], "Bad argument @ 'uiMenuSetItemText' [There's no such row index]")
  if type(arg2) == "string" then
    arg2 = {en = arg2, ar = arg2}
  end
  UI.DB[arg0].data.rows[arg1].text = arg2
  return true
end
function uiMenuGetItemID(arg0, arg1)
  assert(isUIElement(arg0, "menu"), "Bad argument @ 'uiMenuGetRowID' [Expected ui-menu at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1], "Bad argument @ 'uiMenuGetRowID' [There's no such row index]")
  return UI.DB[arg0].data.rows[arg1].id
end
function uiMenuSetItemID(arg0, arg1, arg2)
  assert(isUIElement(arg0, "menu"), "Bad argument @ 'uiMenuSetItemID' [Expected ui-menu at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1], "Bad argument @ 'uiMenuSetItemID' [There's no such row index]")
  UI.DB[arg0].data.rows[arg1].id = arg2
  return true
end
UI.getDrawFunction["ui-menu"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  if dxGetColor(UI.DB[arg0].colors[1]) > 0 then
    dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].colors[1])), 5)
  end
  if 1 <= #UI.DB[arg0].data.rows then
    UI.DB[arg0].data.hovered_row = false
    for forvar16 = UI.DB[arg0].data.row_i, UI.DB[arg0].data.row_f do
      if not isUIDisabled(arg0) and UI.HoveredElement == arg0 then
        if isMouseInPosition(UI.DB[arg0].dimensions.x + 5, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar16].height * SCALE_Y + 4) * (forvar16 - UI.DB[arg0].data.row_i), UI.DB[arg0].data.scrollbar and UI.DB[arg0].dimensions.width - 10 or UI.DB[arg0].dimensions.width, UI.DB[arg0].data.rows[forvar16].height * SCALE_Y) then
          UI.DB[arg0].data.hovered_row = forvar16
        end
      end
      if UI.DB[arg0].data.selected_row == forvar16 then
        dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x + 5, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar16].height * SCALE_Y + 4) * (forvar16 - UI.DB[arg0].data.row_i), UI.DB[arg0].dimensions.width - 10, UI.DB[arg0].data.rows[forvar16].height * SCALE_Y, UI.DB[arg0].properties.selected_row_color.value, 5)
        dxDrawRectangle(UI.DB[arg0].dimensions.x + 5, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar16].height * SCALE_Y + 4) * (forvar16 - UI.DB[arg0].data.row_i) + (UI.DB[arg0].data.rows[forvar16].height * SCALE_Y - anim(UI.DB[arg0].animation[1], 200, 0, 0, 0, 0, UI.DB[arg0].data.rows[forvar16].height * SCALE_Y / 2, 0, 0, 0, "Linear")) / 2, 2, anim(UI.DB[arg0].animation[1], 200, 0, 0, 0, 0, UI.DB[arg0].data.rows[forvar16].height * SCALE_Y / 2, 0, 0, 0, "Linear"), UI.DB[arg0].properties.selection_color.value, UI.postGUI)
      else
        if UI.DB[arg0].data.hovered_row == forvar16 then
        end
        if 0 < bitExtract(UI.DB[arg0].properties.hovered_row_color.value, 24, 8) then
          dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x + 5, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar16].height * SCALE_Y + 4) * (forvar16 - UI.DB[arg0].data.row_i), UI.DB[arg0].dimensions.width - 10, UI.DB[arg0].data.rows[forvar16].height * SCALE_Y, UI.DB[arg0].properties.hovered_row_color.value, 5)
        end
      end
      if UI.DB[arg0].data.rows[forvar16].icon then
        dxDrawImage(UI.DB[arg0].dimensions.x + 5 + 15 * SCALE_Y, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar16].height * SCALE_Y + 4) * (forvar16 - UI.DB[arg0].data.row_i) + (UI.DB[arg0].data.rows[forvar16].height * SCALE_Y - UI.DB[arg0].data.rows[forvar16].height * SCALE_Y / 2) / 2, UI.DB[arg0].data.rows[forvar16].height * SCALE_Y / 2, UI.DB[arg0].data.rows[forvar16].height * SCALE_Y / 2, UI.DB[arg0].data.rows[forvar16].icon, 0, 0, 0, UI.DB[arg0].properties.icons_color.value, UI.postGUI)
      elseif UI.DB[arg0].data.rows[forvar16].emoji then
        local emojiSq = UI.DB[arg0].data.rows[forvar16].height * SCALE_Y / 2
        local emojiX = UI.DB[arg0].dimensions.x + 5 + 15 * SCALE_Y
        local emojiY = UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar16].height * SCALE_Y + 4) * (forvar16 - UI.DB[arg0].data.row_i)
        local emojiScale = emojiSq / (11.5 * SCALE_Y) * 0.52
        dxDrawText(tostring(UI.DB[arg0].data.rows[forvar16].emoji), emojiX, emojiY, emojiX + emojiSq, emojiY + UI.DB[arg0].data.rows[forvar16].height * SCALE_Y, tocolor(255, 255, 255, 235), emojiScale, dxFontEmoji, "center", "center", true, false, UI.postGUI)
      end
      dxDrawText(tostring(UI.DB[arg0].data.rows[forvar16].text[language]), UI.DB[arg0].dimensions.x + 5 + 15 * SCALE_Y + UI.DB[arg0].data.rows[forvar16].height * SCALE_Y / 2 + 10, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar16].height * SCALE_Y + 4) * (forvar16 - UI.DB[arg0].data.row_i), UI.DB[arg0].dimensions.x + 5 + (UI.DB[arg0].dimensions.width - 10), UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar16].height * SCALE_Y + 4) * (forvar16 - UI.DB[arg0].data.row_i) + UI.DB[arg0].data.rows[forvar16].height * SCALE_Y, tocolor(255, 255, 255, 255), 1 * UI.DB[arg0].properties.row_font_scale.value, UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, false, UI.postGUI, true, false)
    end
  end
end
addEventHandler("onClientUIMenuSelectChange", resourceRoot, function()
  UI.DB[source].animation[1] = getTickCount()
end)
