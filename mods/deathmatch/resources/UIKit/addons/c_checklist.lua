-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateCheckList(arg0, arg1, arg2, arg3, arg4, arg5)
  local element = createElement("ui-checklist")
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
      row_f = 1
    },
    align = {
      X = alignX or "left",
      Y = alignY or "top"
    },
    font = {name = dxFont, size = 1},
    properties = {
      row_font_scale = {value = 1, valueType = "number"},
      row_height = {value = 20, valueType = "number"},
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
  addUIElement(element, arg5, sourceResource)
  -- [Fix #42] decompiler bug: the row math reads UI.DB[el].dimensions but the
  -- table above only defines related_dimensions - alias it or every
  -- uiCheckListAddRow crashes with "attempt to index field 'dimensions'".
  UI.DB[element].dimensions = UI.DB[element].related_dimensions
  UI.DB[element].data.scrollbar = uiCreateScrollBar(arg2 - 10, 3, 9, arg3 - 5, tocolor(204, 199, 199), tocolor(255, 255, 255, 0), false, element, tocolor(0, 0, 0, 0))
  uiSetVisible(UI.DB[element].data.scrollbar, false)
  return (element)
end
function calcCLRowsHeight(arg0)
  -- [Fix #42] decompiler bug: the loop body was dropped, so this returned the
  -- LAST row's height only (and crashed on an empty checklist) - sum them all.
  local total = 0
  for _, row in ipairs(UI.DB[arg0].data.rows or {}) do
    total = total + 2 + (row.height or 0) + 4
  end
  return total
end
function findLastCLRow(arg0)
  for forvar5 = UI.DB[arg0].data.row_i, #UI.DB[arg0].data.rows do
    if 2 + UI.DB[arg0].data.rows[forvar5].height + 4 > UI.DB[arg0].dimensions.height then
      return forvar5 - 1
    end
  end
  return #UI.DB[arg0].data.rows
end
function uiCheckListAddRow(arg0, arg1, arg2, arg3)
  assert(isUIElement(arg0, "checklist"), "Bad argument @ 'uiCheckListAddRow' [Expected ui-checklist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  table.insert(UI.DB[arg0].data.rows, {
    text = arg1 or "",
    height = math.min(math.max(UI.DB[arg0].dimensions.height - 2, 0), UI.DB[arg0].properties.row_height.value),
    alignX = "left",
    color = arg2 or tocolor(255, 55, 95, 255),
    selected = arg3 or false,
    animation = {0}
  })
  if doesChecklistNeedScrollBar(arg0) then
    if not uiGetVisible(UI.DB[arg0].data.scrollbar) then
      uiSetVisible(UI.DB[arg0].data.scrollbar, true)
      addEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollCheckList)
    end
  elseif uiGetVisible(UI.DB[arg0].data.scrollbar) then
    removeEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollCheckList)
    uiSetVisible(UI.DB[arg0].data.scrollbar, false)
    scrollCheckList(0, arg0)
  end
  UI.DB[arg0].data.row_f = findLastCLRow(arg0)
  return #UI.DB[arg0].data.rows
end
function scrollCheckList(arg0, arg1)
  if not isUIElement(arg1 or getElementParent(source), "checklist") then
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
function uiCheckListRemoveRow(arg0, arg1)
  assert(isUIElement(arg0, "checklist"), "Bad argument @ 'uiCheckListRemoveRow' [Expected ui-checklist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1], "Bad argument @ 'uiCheckListRemoveRow' [There's no such row index]")
  table.remove(UI.DB[arg0].data.rows, arg1)
  if doesChecklistNeedScrollBar(arg0) then
    if not uiGetVisible(UI.DB[arg0].data.scrollbar) then
      uiSetVisible(UI.DB[arg0].data.scrollbar, true)
      addEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollCheckList)
    end
  elseif uiGetVisible(UI.DB[arg0].data.scrollbar) then
    removeEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollCheckList)
    uiSetVisible(UI.DB[arg0].data.scrollbar, false)
    scrollCheckList(0, arg0)
  end
  UI.DB[arg0].data.row_f = findLastCLRow(arg0)
  return true
end
function uiCheckListClear(arg0)
  assert(isUIElement(arg0, "checklist"), "Bad argument @ 'uiCheckListClear' [Expected ui-checklist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].data.rows = {}
  scrollCheckList(0, arg0)
  return true
end
function uiCheckListGetRowCount(arg0)
  assert(isUIElement(arg0, "checklist"), "Bad argument @ 'uiCheckListGetRowCount' [Expected ui-checklist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return #UI.DB[arg0].data.rows
end
function uiCheckListGetSelectedItems(arg0)
  assert(isUIElement(arg0, "checklist"), "Bad argument @ 'uiCheckListGetSelectedItems' [Expected ui-checklist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  -- [Fix #42] decompiler bug: the result table was anonymous ({}), so the
  -- selected rows were collected into thin air and the function always
  -- returned {} - the faction duty-perks checklist could never save.
  local result = {}
  for row, data in ipairs(UI.DB[arg0].data.rows) do
    if data.selected then
      table.insert(result, row)
    end
  end
  return result
end
function uiCheckListGetItemText(arg0, arg1)
  assert(isUIElement(arg0, "checklist"), "Bad argument @ 'uiCheckListGetItemText' [Expected ui-checklist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1], "Bad argument @ 'uiCheckListGetItemText' [There's no such row index]")
  return UI.DB[arg0].data.rows[arg1].text
end
function uiCheckListSetItemText(arg0, arg1, arg2)
  assert(isUIElement(arg0, "checklist"), "Bad argument @ 'uiCheckListSetItemText' [Expected ui-checklist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1], "Bad argument @ 'uiCheckListSetItemText' [There's no such row index]")
  assert(type(arg2) == "string", "Bad argument @ 'uiCheckListSetItemText' [Expected string at argument 3, got " .. type(arg2) .. "]")
  UI.DB[arg0].data.rows[arg1].text = arg2
  return true
end
UI.getDrawFunction["ui-checklist"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].colors[1])), 5)
  if 1 <= #UI.DB[arg0].data.rows then
    UI.DB[arg0].data.hovered_row = false
    for forvar14 = UI.DB[arg0].data.row_i, UI.DB[arg0].data.row_f do
      if not isUIDisabled(arg0) and UI.HoveredElement == arg0 then
        if isMouseInPosition(UI.DB[arg0].dimensions.x + 5, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar14].height + 4) * (forvar14 - UI.DB[arg0].data.row_i), UI.DB[arg0].data.scrollbar and UI.DB[arg0].dimensions.width - 10 or UI.DB[arg0].dimensions.width, UI.DB[arg0].data.rows[forvar14].height) then
          UI.DB[arg0].data.hovered_row = forvar14
        end
      end
      if UI.DB[arg0].data.rows[forvar14].selected then
        -- [Fix #158] a selected/checked row gets the same solid BLUE rectangle
        -- as every other list: full row width + full row height, drawn UNDER
        -- the check box, the checkmark and the text (nothing forced white).
        dxDrawRectangle(UI.DB[arg0].dimensions.x + 5, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar14].height + 4) * (forvar14 - UI.DB[arg0].data.row_i), UI.DB[arg0].dimensions.width - 10, UI.DB[arg0].data.rows[forvar14].height, tocolor(45, 110, 225, 255), UI.postGUI)
      end
      dxDrawRectangle(UI.DB[arg0].dimensions.x + 5, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar14].height + 4) * (forvar14 - UI.DB[arg0].data.row_i), UI.DB[arg0].data.rows[forvar14].height, UI.DB[arg0].data.rows[forvar14].height, tocolor(60, 60, 60, 255), UI.postGUI)
      dxDrawRectangle(UI.DB[arg0].dimensions.x + 5 + 2, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar14].height + 4) * (forvar14 - UI.DB[arg0].data.row_i) + 2, UI.DB[arg0].data.rows[forvar14].height - 4, UI.DB[arg0].data.rows[forvar14].height - 4, tocolor(anim(UI.DB[arg0].data.rows[forvar14].animation[1], 500, dxGetColor(UI.DB[arg0].data.rows[forvar14].color))), UI.postGUI)
      if UI.DB[arg0].data.rows[forvar14].selected then
        dxDrawLine(UI.DB[arg0].dimensions.x + 5 + 4, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar14].height + 4) * (forvar14 - UI.DB[arg0].data.row_i) + 6, UI.DB[arg0].dimensions.x + 5 + 4, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar14].height + 4) * (forvar14 - UI.DB[arg0].data.row_i) + UI.DB[arg0].data.rows[forvar14].height - 5, tocolor(255, 255, 255, 255), 1, UI.postGUI)
        dxDrawLine(UI.DB[arg0].dimensions.x + 5 + 4, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar14].height + 4) * (forvar14 - UI.DB[arg0].data.row_i) + UI.DB[arg0].data.rows[forvar14].height - 5, UI.DB[arg0].dimensions.x + 5 + 11, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar14].height + 4) * (forvar14 - UI.DB[arg0].data.row_i) + 3, tocolor(255, 255, 255, 255), 1, UI.postGUI)
      end
      dxDrawText(tostring(UI.DB[arg0].data.rows[forvar14].text), UI.DB[arg0].dimensions.x + 5 + UI.DB[arg0].data.rows[forvar14].height + 5, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar14].height + 4) * (forvar14 - UI.DB[arg0].data.row_i), UI.DB[arg0].dimensions.x + 5 + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + 5 + (UI.DB[arg0].data.rows[forvar14].height + 4) * (forvar14 - UI.DB[arg0].data.row_i) + UI.DB[arg0].data.rows[forvar14].height, tocolor(255, 255, 255, UI.DB[arg0].data.hovered_row == forvar14 and 160 or 255), 1, UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, false, UI.postGUI, true, false)
    end
  end
end
