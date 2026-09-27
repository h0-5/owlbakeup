-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateGridList(arg0, arg1, arg2, arg3, arg4, arg5)
  local element = createElement("ui-gridlist")
  UI.DB[element] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    colors = {
      arg4 or tocolor(0, 0, 0)
    },
    data = {
      columns = {},
      rows = {},
      page = 1,
      selected_row = -1,
      row_i = 1,
      row_f = 1
    },
    align = {
      X = alignX or "left",
      Y = alignY or "center"
    },
    font = {name = dxFont, size = 1},
    properties = {
      column_font_scale = {value = 1, valueType = "number"},
      column_height = {value = 25, valueType = "number"},
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
      },
      columns_names_visible = {
        value = "True",
        valueType = "string",
        acceptedValues = {"True", "False"}
      },
      color_coded = {value = false, valueType = "boolean"}
    }
  }
  addUIElement(element, arg5, sourceResource)
  UI.DB[element].data.scrollbar = uiCreateScrollBar(arg2 - 8, UI.DB[element].properties.column_height.value + 3, 6, arg3 - UI.DB[element].properties.column_height.value - 5, theme.COLORS.scrollbar_default, tocolor(255, 255, 255, 0), false, element, tocolor(0, 0, 0, 0))
  uiSetVisible(UI.DB[element].data.scrollbar, false)
  return (element)
end
function uiGridListAddColumn(arg0, arg1, arg2)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListAddColumn' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "string", "Bad argument @ 'uiGridListAddColumn' [Expected string at argument 2, got " .. type(arg1) .. "]")
  assert(type(arg2) == "number", "Bad argument @ 'uiGridListAddColumn' [Expected number at argument 3, got " .. type(arg2) .. "]")
  table.insert(UI.DB[arg0].data.columns, {
    text = arg1,
    width = math.max(math.min(arg2, 1), 0)
  })
  return #UI.DB[arg0].data.columns
end
function uiGridListAddRow(arg0)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListAddRow' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  -- REPAIR (gridlist fix): the decompiled original inserted the row
  -- cells into a throwaway table and pushed an EMPTY row, so the very
  -- first AddRow crashed in the height math and every SetItem*/Get*
  -- call afterwards indexed a nil cell. Build cells into the real row.
  local rowIndex = #UI.DB[arg0].data.rows + 1
  UI.DB[arg0].data.rows[rowIndex] = {}
  for forvar5, forvar6 in ipairs(UI.DB[arg0].data.columns) do
    UI.DB[arg0].data.rows[rowIndex][forvar5] = {
      text = "",
      height = math.min(math.max(UI.DB[arg0].dimensions.height - 2, 0), UI.DB[arg0].properties.row_height.value * SCALE_Y),
      width = forvar6.width,
      alignX = "left"
    }
  end
  if doesGridlistNeedScrollBar(arg0) then
    if not uiGetVisible(UI.DB[arg0].data.scrollbar) then
      uiSetVisible(UI.DB[arg0].data.scrollbar, true)
      addEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollGridList)
    end
  elseif uiGetVisible(UI.DB[arg0].data.scrollbar) then
    removeEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollGridList)
    uiSetVisible(UI.DB[arg0].data.scrollbar, false)
    scrollGridList(0, arg0)
  end
  UI.DB[arg0].data.row_f = findLastRow(arg0)
  return #UI.DB[arg0].data.rows - 1
end
-- [Vortex scroll fix] the decompiled original measured only the LAST row
-- height (not the cumulative total), so doesGridlistNeedScrollBar was
-- always false and findLastRow returned every row -> lists painted past
-- their borders with no scrolling (the /staffs ranks + permissions
-- overflow). Cumulative rebuild: scrollbars appear, the wheel scrolls,
-- and rows clip at the list bounds on EVERY UIKit gridlist.
function scrollGridList(arg0, arg1)
  if not isUIElement(arg1 or getElementParent(source), "gridlist") then
    return
  end
  local db = UI.DB[arg1 or getElementParent(source)]
  local rows = db.data.rows
  local scrolled = calcRowsHeight(arg1 or getElementParent(source)) / 100 * (tonumber(arg0) or 0)
  local acc = 2 + db.properties.column_height.value
  local newI = math.max(1, #rows)
  for forvar8 = 1, #rows do
    local rowCell = rows[forvar8] and rows[forvar8][1]
    if rowCell then
      if scrolled <= acc then
        newI = forvar8
        break
      end
      acc = acc + (rowCell.height or 0)
    end
  end
  db.data.row_i = math.min(newI, math.max(1, #rows))
  db.data.row_f = findLastRow(arg1 or getElementParent(source))
end
function calcRowsHeight(arg0)
  local rows = UI.DB[arg0].data.rows or {}
  if #rows == 0 then
    return 0
  end
  local total = 2
  for forvar5 = 1, #rows do
    local rowCell = rows[forvar5] and rows[forvar5][1]
    if rowCell then
      total = total + (rowCell.height or 0)
    end
  end
  return total
end
function findLastRow(arg0)
  local viewport = UI.DB[arg0].dimensions.height - UI.DB[arg0].properties.column_height.value - 2
  if viewport <= 0 then
    return UI.DB[arg0].data.row_i
  end
  local used = 0
  for forvar5 = UI.DB[arg0].data.row_i, #UI.DB[arg0].data.rows do
    local rowCell = UI.DB[arg0].data.rows[forvar5] and UI.DB[arg0].data.rows[forvar5][1]
    if not rowCell then
      return #UI.DB[arg0].data.rows
    end
    used = used + (rowCell.height or 0)
    if used > viewport then
      return math.max(UI.DB[arg0].data.row_i, forvar5 - 1)
    end
  end
  return #UI.DB[arg0].data.rows
end
function doesGridlistNeedScrollBar(arg0)
  return UI.DB[arg0].properties.column_height.value + calcRowsHeight(arg0) > UI.DB[arg0].dimensions.height
end
function uiGridListRemoveRow(arg0, arg1)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListRemoveRow' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1 + 1], "Bad argument @ 'uiGridListRemoveRow' [There's no such row index]")
  table.remove(UI.DB[arg0].data.rows, arg1 + 1)
  if doesGridlistNeedScrollBar(arg0) then
    if not uiGetVisible(UI.DB[arg0].data.scrollbar) then
      uiSetVisible(UI.DB[arg0].data.scrollbar, true)
      addEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollGridList)
    end
  elseif uiGetVisible(UI.DB[arg0].data.scrollbar) then
    removeEventHandler("onClientUIScroll", UI.DB[arg0].data.scrollbar, scrollGridList)
    uiSetVisible(UI.DB[arg0].data.scrollbar, false)
    scrollGridList(0, arg0)
  end
  UI.DB[arg0].data.row_f = findLastRow(arg0)
  return true
end
function uiGridListRemoveColumn(arg0, arg1)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListRemoveColumn' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.columns[arg1], "Bad argument @ 'uiGridListRemoveColumn' [There's no such column index]")
  table.remove(UI.DB[arg0].data.columns, arg1)
  return true
end
function uiGridListClear(arg0)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListClear' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].data.rows = {}
  UI.DB[arg0].data.selected_row = -1
  -- [Vortex fix] reset the thumb too, otherwise a stale scroll position
  -- desyncs it from the freshly emptied list
  if isElement(UI.DB[arg0].data.scrollbar) then
    uiScrollBarSetScrollPosition(UI.DB[arg0].data.scrollbar, 0)
  end
  scrollGridList(0, arg0)
  return true
end
function uiGridListGetColumnCount(arg0)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListGetColumnCount' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return #UI.DB[arg0].data.columns
end
function uiGridListGetRowCount(arg0)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListGetRowCount' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return #UI.DB[arg0].data.rows
end
function uiGridListGetColumnText(arg0, arg1)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListGetColumnText' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.columns[arg1], "Bad argument @ 'uiGridListGetColumnText' [There's no such column index]")
  return UI.DB[arg0].data.columns[arg1].text
end
function uiGridListGetColumnColor(arg0, arg1)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListGetColumnColor' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.columns[arg1], "Bad argument @ 'uiGridListGetColumnColor' [There's no such column index]")
  return dxGetColor(UI.DB[arg0].data.columns[arg1].color) or 255, 255, 255, 255
end
function uiGridListGetItemText(arg0, arg1, arg2)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListGetItemText' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.columns[arg2], "Bad argument @ 'uiGridListGetItemText' [There's no such column index]")
  assert(UI.DB[arg0].data.rows[arg1 + 1], "Bad argument @ 'uiGridListGetItemText' [There's no such row index]")
  local cell = UI.DB[arg0].data.rows[arg1 + 1][arg2]
  return cell and cell.text or ""
end
function uiGridListGetItemData(arg0, arg1, arg2)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListGetItemData' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.columns[arg2], "Bad argument @ 'uiGridListGetItemData' [There's no such column index]")
  assert(UI.DB[arg0].data.rows[arg1 + 1], "Bad argument @ 'uiGridListGetItemData' [There's no such row index]")
  local cell = UI.DB[arg0].data.rows[arg1 + 1][arg2]
  return cell and cell.data
end
function uiGridListGetSelectedItem(arg0)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListGetSelectedItem' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if not UI.DB[arg0].data.rows[UI.DB[arg0].data.selected_row + 1] then
    UI.DB[arg0].data.selected_row = -1
  end
  return UI.DB[arg0].data.selected_row
end
-- [Fix #17] scroll-aware helpers used by the staff panel's raw click layer.
-- The panel recomputed the clicked row from the cursor Y alone, which ignored
-- the scroll offset (data.row_i) and picked the wrong rank after scrolling.
-- These mirror the draw loop's own geometry so a click lands on the row that
-- is actually painted under the cursor.
function uiGridListGetVisibleRows(arg0)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListGetVisibleRows' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.row_i or 1, UI.DB[arg0].data.row_f or 1
end
function uiGridListGetRowAtPoint(arg0, ay)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListGetRowAtPoint' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  local db = UI.DB[arg0]
  local rows = db.data.rows or {}
  if #rows == 0 then return -1 end
  local ch = db.properties.column_height.value
  for i = db.data.row_i or 1, db.data.row_f or #rows do
    local cell = rows[i] and rows[i][1]
    if not cell then break end
    local ry = db.dimensions.y + 2 + ch + cell.height * (i - db.data.row_i)
    if ay >= ry and ay <= ry + cell.height then
      return i - 1
    end
  end
  return -1
end
function uiGridListSetColumnText(arg0, arg1, arg2)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListSetColumnText' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.columns[arg1], "Bad argument @ 'uiGridListSetColumnText' [There's no such column index]")
  assert(type(arg2) == "string", "Bad argument @ 'uiGridListSetColumnText' [Expected string at argument 3, got " .. type(arg2) .. "]")
  UI.DB[arg0].data.columns[arg1].text = arg2
  return true
end
function uiGridListSetColumnColor(arg0, arg1, arg2)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListSetColumnColor' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.columns[arg1], "Bad argument @ 'uiGridListSetColumnColor' [There's no such column index]")
  assert(type(arg2) == "number", "Bad argument @ 'uiGridListSetColumnColor' [Expected number at argument 3, got " .. type(arg2) .. "]")
  UI.DB[arg0].data.columns[arg1].color = arg2
  return true
end
function uiGridListSetItemText(arg0, arg1, arg2, arg3, arg4)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListSetItemText' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1 + 1], "Bad argument @ 'uiGridListSetItemText' [There's no such row index]")
  assert(UI.DB[arg0].data.columns[arg2], "Bad argument @ 'uiGridListSetItemText' [There's no such column index]")
  assert(type(arg3) == "string", "Bad argument @ 'uiGridListSetColumnText' [Expected string at argument 4, got " .. type(arg3) .. "]")
  UI.DB[arg0].data.rows[arg1 + 1][arg2].text = arg3
  UI.DB[arg0].data.rows[arg1 + 1][arg2].alignX = arg4 or "left"
  return true
end
function uiGridListSetItemData(arg0, arg1, arg2, arg3)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListSetItemData' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1 + 1], "Bad argument @ 'uiGridListSetItemData' [There's no such row index]")
  assert(UI.DB[arg0].data.columns[arg2], "Bad argument @ 'uiGridListSetItemData' [There's no such column index]")
  UI.DB[arg0].data.rows[arg1 + 1][arg2].data = arg3
  return true
end
function uiGridListSetItemColor(arg0, arg1, arg2, arg3)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListSetItemColor' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1 + 1], "Bad argument @ 'uiGridListSetItemColor' [There's no such row index]")
  assert(UI.DB[arg0].data.columns[arg2], "Bad argument @ 'uiGridListSetItemColor' [There's no such column index]")
  assert(type(arg3) == "number", "Bad argument @ 'uiGridListSetColumnColor' [Expected number at argument 4, got " .. type(arg3) .. "]")
  UI.DB[arg0].data.rows[arg1 + 1][arg2].color = arg3
  return true
end
function uiGridListGetItemColor(arg0, arg1, arg2)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListSetItemColor' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].data.rows[arg1 + 1], "Bad argument @ 'uiGridListSetItemColor' [There's no such row index]")
  assert(UI.DB[arg0].data.columns[arg2], "Bad argument @ 'uiGridListSetItemColor' [There's no such column index]")
  return dxGetColor(UI.DB[arg0].data.rows[arg1 + 1][arg2].color or tocolor(255, 255, 255, 255))
end
function uiGridListSetSelectedItem(arg0, arg1)
  assert(isUIElement(arg0, "gridlist"), "Bad argument @ 'uiGridListSetSelectedItem' [Expected ui-gridlist at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if arg1 ~= -1 then
    assert(UI.DB[arg0].data.rows[arg1 + 1], "Bad argument @ 'uiGridListSetSelectedItem' [There's no such row index]")
  end
  UI.DB[arg0].data.selected_row = arg1
  -- [Vortex fix #11] stamp the moment of selection so the draw can fade in
  UI.DB[arg0].data.selection_tick = getTickCount()
  return true
end
UI.getDrawFunction["ui-gridlist"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  if dxGetColor(UI.DB[arg0].colors[1]) and dxGetColor(UI.DB[arg0].colors[1]) > 0 then
    dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(UI.DB[arg0].colors[1])), 5)
  end
  if 1 <= #UI.DB[arg0].data.columns then
    local columnX, columnOffset = {}, 0
    for forvar17, forvar18 in ipairs(UI.DB[arg0].data.columns) do
      columnX[forvar17] = UI.DB[arg0].dimensions.x + columnOffset
      columnOffset = columnOffset + forvar18.width * UI.DB[arg0].dimensions.width
      if UI.DB[arg0].properties.columns_names_visible.value == "True" then
        dxDrawText(forvar18.text, columnX[forvar17] + (UI.DB[arg0].align.X == "left" and 5 or 0), UI.DB[arg0].dimensions.y, columnX[forvar17] + forvar18.width * UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].properties.column_height.value, forvar18.color or tocolor(255, 255, 255, 255), UI.DB[arg0].properties.column_font_scale.value, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, _, UI.postGUI) -- [Vortex fix] header x = columnX (the decompiled draw used the gridlist left edge for EVERY column -> all headers stacked on top of each other)
      end
    end
    if UI.DB[arg0].properties.columns_names_visible.value == "True" then
      dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[arg0].properties.column_height.value, UI.DB[arg0].dimensions.width, 1.5, tocolor(255, 255, 255, 150), UI.postGUI)
    end
    if 1 <= #UI.DB[arg0].data.rows then
      UI.DB[arg0].data.hovered_row = false
      -- [Vortex fix #14] row banding rebuilt. The decompiled draw painted the
      -- selection rectangle PER CELL (a 5-column list stroked the same rect 5x,
      -- alpha stacking into a near-opaque purple slab that drowned the row
      -- text -> "the name disappears when I click" + harsh fade = broken
      -- animation). The highlight is now drawn ONCE per row, BEFORE the cells,
      -- with a subtle alpha cap so every rank color / name stays readable.
      for forvar19 = UI.DB[arg0].data.row_i, UI.DB[arg0].data.row_f do
        local rowCell1 = UI.DB[arg0].data.rows[forvar19][1]
        local rowH = (rowCell1 and rowCell1.height) or 20
        local rowY = UI.DB[arg0].dimensions.y + 2 + UI.DB[arg0].properties.column_height.value + rowH * (forvar19 - UI.DB[arg0].data.row_i)
        if UI.DB[arg0].data.selected_row == forvar19 - 1 then
          -- [Vortex fix #15] the band is drawn ONCE per row (fix #14 killed the
          -- per-cell overdraw), so it can be stronger without drowning the text:
          -- fade 60 -> 170 over ~140ms = clearly "prominent + white" on the
          -- promote/demote rank lists, text stays forced white and readable.
          local selTick = UI.DB[arg0].data.selection_tick
          local selAlpha = 170
          if selTick then
            local selDT = getTickCount() - selTick
            if selDT < 140 then
              selAlpha = math.floor(60 + (170 - 60) * (selDT / 140))
            end
          end
          dxDrawRectangle(UI.DB[arg0].dimensions.x, rowY + 1, UI.DB[arg0].dimensions.width, rowH - 1, tocolor(dxGetColor(theme.COLORS.primary), selAlpha), UI.postGUI)
          -- accent bar on the left edge keeps the selection unmistakable
          dxDrawRectangle(UI.DB[arg0].dimensions.x, rowY + 1, 3, rowH - 1, tocolor(dxGetColor(theme.COLORS.primary), 255), UI.postGUI)
        end
        if not isUIDisabled(arg0) and UI.HoveredElement == arg0
          and isMouseInPosition(UI.DB[arg0].dimensions.x, rowY, UI.DB[arg0].data.scrollbar and UI.DB[arg0].dimensions.width - 10 or UI.DB[arg0].dimensions.width, rowH) then
          UI.DB[arg0].data.hovered_row = forvar19 - 1
          if UI.DB[arg0].data.selected_row ~= forvar19 - 1 then
            dxDrawRectangle(UI.DB[arg0].dimensions.x, rowY + 1, UI.DB[arg0].dimensions.width, rowH - 1, tocolor(60, 60, 60, 90), UI.postGUI)
          end
        end
        for forvar24, forvar25 in ipairs(UI.DB[arg0].data.rows[forvar19]) do
          -- [Vortex fix #14b] selected row text is forced WHITE: rank colors
          -- like navy/maroon drowned on the selection band and the name
          -- looked like it "disappears" when clicked
          local cellColor = forvar25.color or tocolor(255, 255, 255, 255)
          if UI.DB[arg0].data.selected_row == forvar19 - 1 then
            cellColor = tocolor(255, 255, 255, 255)
          end
          dxDrawText(forvar25.text, columnX[forvar24] + (forvar25.alignX == "left" and 5 or 0), UI.DB[arg0].dimensions.y + 2 + UI.DB[arg0].properties.column_height.value + forvar25.height * (forvar19 - UI.DB[arg0].data.row_i), columnX[forvar24] + forvar25.width * UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + 2 + UI.DB[arg0].properties.column_height.value + forvar25.height * (forvar19 - UI.DB[arg0].data.row_i) + forvar25.height, cellColor, UI.DB[arg0].properties.row_font_scale.value, UI.DB[arg0].font.name, forvar25.alignX, "center", true, _, UI.postGUI, UI.DB[arg0].properties.color_coded.value)
          dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 2 + UI.DB[arg0].properties.column_height.value + forvar25.height * (forvar19 - UI.DB[arg0].data.row_i) + forvar25.height, UI.DB[arg0].dimensions.width, 0.5, tocolor(255, 255, 255, 5), UI.postGUI, UI.subPixelPositioning)
        end
      end
    end
  end
end
function MouseWheel(arg0, arg1)
  if not isUIElement(UI.HoveredElement, "gridlist") then
    return
  end
  if isElement(UI.DB[UI.HoveredElement].data.scrollbar) then
    -- [Vortex fix] +-5% per notch (same step the memo uses) so long lists
    -- like the 44-row permissions table are navigable by wheel
    uiScrollBarSetScrollPosition(UI.DB[UI.HoveredElement].data.scrollbar, (tonumber(UI.DB[UI.DB[UI.HoveredElement].data.scrollbar].data.scroll) or 0) + (arg0 == "mouse_wheel_up" and -5 or 5))
  end
end
bindKey("mouse_wheel_up", "both", MouseWheel)
bindKey("mouse_wheel_down", "both", MouseWheel)
