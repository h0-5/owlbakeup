-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

moveTemp = {}

-- [Vortex fix] locals lost by the decompiler, reconstructed:
local repeatTimer, repeatCount = false, 0
local clickTimer1, clickTimer2 = false, false
local cancelKeys = {
        backspace = true, delete = true, enter = true, num_enter = true,
        arrow_l = true, arrow_r = true, arrow_u = true, arrow_d = true,
}
local function isTypableCharacter(ch)
        return type(ch) == "string" and #ch > 0 and ch:byte() >= 32 and ch:byte() ~= 127
end
-- [Fix #83 - user] one shared funnel for backspace / delete / arrows / enter,
-- fed by BOTH the original bindKey handlers and the onClientKey dispatcher
-- below, with a per key+state dedup: a single physical press can never
-- delete/insert twice no matter how many input modes are alive (the login
-- screen's guiSetInputEnabled(true) kills binds, normal play keeps them).
local TEXT_KEYS = {
  backspace = true, delete = true,
  arrow_l = true, arrow_r = true, arrow_u = true, arrow_d = true,
  enter = true, num_enter = true
}
local lastTextKey, lastTextState, lastTextTick = false, false, 0
local function nativeOwnsTextKeys()
  -- isChatBoxOpen() / guiGetFocusedElement() do NOT exist in this MTA build:
  -- the old guard crashed with "attempt to call global 'isChatBoxOpen'"
  -- on every filtered key press, so backspace/delete/arrows/enter never
  -- reached removeText/moveCaret/acceptedEvent from onClientKey
  if isChatBoxInputActive and isChatBoxInputActive() then return true end
  if guiGetFocusedElement then
    local ok, el = pcall(guiGetFocusedElement)
    if ok and el then return true end
  end
  return false
end
function handleTextKey(key, state)
  if nativeOwnsTextKeys() then return end
  local now = getTickCount()
  if key == lastTextKey and state == lastTextState and now - lastTextTick < 60 then
    return
  end
  lastTextKey, lastTextState, lastTextTick = key, state, now
  if key == "backspace" or key == "delete" then
    removeText(key, state)
  elseif key == "enter" or key == "num_enter" then
    acceptedEvent(key, state)
  else
    moveCaret(key, state)
  end
end
-- [Fix #83 - user] while typing in ANY UIKit input every other key is
-- canceled, so game binds / GTA controls stay silent (WASD, space, weapons,
-- F-keys, TAB ...) and come back automatically the moment the user clicks
-- outside the text rect (focus cleared). Keys UIKit itself needs while
-- typing stay whitelisted; mouse keys are never canceled so clicking still
-- defocuses. onClientCharacter (actual letters) is a separate event and is
-- not affected by cancelEvent.
local typingSafeKeys = {
  backspace = true, delete = true,
  arrow_l = true, arrow_r = true, arrow_u = true, arrow_d = true,
  enter = true, num_enter = true,
  mouse1 = true, mouse2 = true, mouse3 = true, mouse4 = true, mouse5 = true,
  mouse_wheel_up = true, mouse_wheel_down = true
}
function isTypingFocus()
  local el = UI.FocusElement
  if not el or not isElement(el) then return false end
  local t = getElementType(el)
  if t ~= "ui-edit" and t ~= "ui-memo" then return false end
  local db = UI.DB[el]
  if not db or not db.data or not db.visible then return false end
  if db.data.readonly then return false end
  return true
end
local function allowWhileTyping(key)
  if typingSafeKeys[key] then return true end
  -- ctrl+A/C/X (select all / copy / cut) binds read getKeyState() themselves,
  -- so the letter key events must survive while ctrl is held
  if key == "a" or key == "c" or key == "x" or key == "v" then
    if getKeyState("lctrl") or getKeyState("rctrl") then return true end
  end
  return false
end
function updateLabelScroll(label)
        if UI.DB[label] and UI.DB[label].scrollbar and UI.DB[label].scrollbar.element then
                uiScrollBarSetScrollPosition(UI.DB[label].scrollbar.element, 0)
        end
        return true
end
function UI.updateDrawingList()
  UI.DrawElements = {}
  -- [Fix #30 - FPS] resolve each element's draw function + type ONCE here
  -- (this runs on visibility changes) instead of calling getElementType
  -- several times per element per frame inside UI.drawing
  UI.DrawFn = {}
  UI.EType = {}
  for i = 1, #UI.Elements do
    local el = UI.Elements[i]
    if UI.DB[el] and UI.DB[el].visible and UI.isInDrawingList[el] and UI.isHierarchyVisible(el) then
      -- [Vortex fix] an element nested ANYWHERE under a ui-tab is armed ONLY
      -- while that tab is its tabpanel's selected tab. Arming every tab's
      -- subtree drew ALL tab contents stacked on the selected one (info
      -- cards under the vehicles grid, doubled gridlist headers, phantom
      -- white lines, stolen clicks). The tab may sit higher in the tree
      -- (tab -> card rectangle -> label), so walk the whole chain.
      local owningTab, owningTabpanel = nil, nil
      local ancestor = getElementParent(el)
      while ancestor and isElement(ancestor) and isUIElement(ancestor) do
        if getElementType(ancestor) == "ui-tab" then
          owningTab = ancestor
          owningTabpanel = getElementParent(ancestor)
          break
        end
        ancestor = getElementParent(ancestor)
      end
      if owningTab then
        if owningTabpanel and isElement(owningTabpanel) and UI.DB[owningTabpanel]
                and UI.DB[owningTabpanel].data and UI.DB[owningTabpanel].data.selected_tab == owningTab then
          UI.DrawElements[#UI.DrawElements + 1] = el
          UI.DrawFn[el] = UI.getDrawFunction[getElementType(el)]
          UI.EType[el] = getElementType(el)
          UI.isDraw[el] = true
        end
      else
        UI.DrawElements[#UI.DrawElements + 1] = el
        UI.DrawFn[el] = UI.getDrawFunction[getElementType(el)]
        UI.EType[el] = getElementType(el)
        -- [Vortex fix] ui-tab elements themselves are armed per-frame by
        -- their tabpanel draw (selected tab only)
        if getElementType(el) ~= "ui-tab" then
          UI.isDraw[el] = true
        end
      end
    end
  end
end
function UI.drawing()
  UI.HoveredElement = false
  local hoverCandidate = false
  local anyDrawn = false
  -- [Fix #30 - FPS] ONE cursor read per frame (was: two natives per element
  -- per frame - isCursorShowing + getCursorPosition inside the loop)
  local cursorShowing = isCursorShowing()
  local ccx, ccy = getCursorPosition()
  for forvar3 = 1, #UI.DrawElements do
    local el = UI.DrawElements[forvar3]
    if isUIElement(el) then
      if UI.DB[el].visible then
        if UI.isDraw[el] then
          local elType = UI.EType[el] or getElementType(el)
          UI.EType[el] = elType
          if elType ~= "ui-tab" then
            hoverCandidate = isMouseInPosition(UI.DB[el].dimensions.x, UI.DB[el].dimensions.y, UI.DB[el].dimensions.width, UI.DB[el].dimensions.height) and el or hoverCandidate
          end
          if elType ~= "ui-button" and cursorShowing and UI.DB[el].state == "clicked" and UI.DB[el].state ~= "normal" then
            UI.DB[el].state = "normal"
            if isEventHandlerAdded("onClientCursorMove", root, moveElement) then
              removeEventHandler("onClientCursorMove", root, moveElement)
              moveTemp = {}
            end
          end
          local drawFn = (UI.DrawFn and UI.DrawFn[el]) or UI.getDrawFunction[elType]
          if not drawFn then
            drawFn = UI.getDrawFunction[elType]
            if UI.DrawFn then UI.DrawFn[el] = drawFn end
          end
          if type(drawFn) == "function" then
            drawFn(el)
            UI.isDraw[el] = true
            anyDrawn = true
          end
          UI.TempDisabled[el] = UI.DB[el].properties.Disabled.value == "True"
        end
      end
      if not UI.isDraw[el] then
        UI.isDraw[el] = false
        if UI.FocusElement == el then
          UI.FocusElement = false
          UI.DB[el].state = "normal"
          triggerEvent("onClientUIBlur", el)
        end
        if UI.HoveredElement == el then
          UI.HoveredElement = false
        end
      end
    end
  end
  if hoverCandidate ~= UI.TempHoveredElement then
    if UI.TempHoveredElement and isUIElement(UI.TempHoveredElement) then
      UI.DB[UI.TempHoveredElement].data.leaveTick = getTickCount()
      triggerEvent("onClientUIMouseLeave", UI.TempHoveredElement)
    end
    UI.TempHoveredElement = hoverCandidate
    if hoverCandidate then
      if getElementType(hoverCandidate) == "ui-edit" and UI.FocusElement ~= hoverCandidate then
        UI.DB[hoverCandidate].animation = {
          getTickCount(),
          true
        }
      end
      UI.DB[hoverCandidate].data.enterTick = getTickCount()
      triggerEvent("onClientUIMouseEnter", hoverCandidate)
    end
  end
  if not anyDrawn then
    UI.renderStatus = false
    removeEventHandler("onClientRender", root, UI.drawing)
    if UI.FocusElement then
      UI.DB[UI.FocusElement].state = "normal"
      triggerEvent("onClientUIBlur", UI.FocusElement)
      UI.FocusElement = false
    end
  end
end
addEventHandler("onClientRender", root, UI.drawing)
-- [Vortex fix #12] hover state is inherently one frame stale (it is
-- recomputed inside onClientRender); a click processed in that gap used
-- the PREVIOUS cursor position and was dropped entirely. Recompute the
-- topmost element under the cursor at the moment of the click itself.
-- [Vortex fix #15] the tab BAR is drawn ABOVE the tabpanel rect
-- (y - tab_height - 2), so a click landing on a tab never hit-tested the
-- tabpanel after #12 made hover click-time -- switching tabs (F1 personal
-- info / vehicles / interiors, leaderboard) became impossible. Two parts:
--   1. refreshHover extends the hit rect of ui-tabpanel upwards into the bar
--   2. hovered_tab is recomputed at click time (it is a DRAWN state, one
--      frame stale otherwise)
function UI.refreshTabpanelHoverTab(arg0, ax, ay)
  local db = UI.DB[arg0]
  if not db or not db.data then return end
  db.data.hovered_tab = nil
  local n = #db.data.visible_tabs
  if n == 0 then return end
  local slotW = (db.dimensions.width - 5 * (n + 1) * SCALE_Y) / n
  local slotY = db.dimensions.y - db.properties.tab_height.value * SCALE_Y - 2 * SCALE_Y
  local slotH = db.properties.tab_height.value * SCALE_Y
  for i = 1, n do
    local slotX = db.dimensions.x + 5 * SCALE_Y + (slotW + 5 * SCALE_Y) * (i - 1)
    if ax >= slotX and ax <= slotX + slotW and ay >= slotY and ay <= slotY + slotH then
      db.data.hovered_tab = db.data.visible_tabs[i]
      return
    end
  end
end
function UI.refreshHover()
  local cx, cy = getCursorPosition()
  if not cx then
    return false
  end
  local ax, ay = cx * sx, cy * sy
  for i = #UI.DrawElements, 1, -1 do
    local el = UI.DrawElements[i]
    if isUIElement(el) and getElementType(el) ~= "ui-tab" and UI.DB[el] and UI.DB[el].visible and UI.isDraw[el] and UI.DB[el].dimensions then
      local d = UI.DB[el].dimensions
      local hitTop = d.y
      if getElementType(el) == "ui-tabpanel" then
        hitTop = d.y - UI.DB[el].properties.tab_height.value * SCALE_Y - 2 * SCALE_Y
          - (UI.DB[el].properties.title_shown.value and UI.DB[el].properties.title_height.value * SCALE_Y or 0)
        UI.refreshTabpanelHoverTab(el, ax, ay)
      end
      if ax >= d.x and ay >= hitTop and ax <= d.x + d.width and ay <= d.y + d.height and not isUIDisabled(el) then
        return el
      end
    end
  end
  return false
end
-- [Vortex fix #12] hovered_row / hovered rows are DRAWN state: they are
-- recomputed inside the element draw, so a click landing in the frame gap
-- used the previous cursor position. Refresh them at click time.
function UI.refreshGridlistHoverRow(arg0)
  local db = UI.DB[arg0]
  if not db or not db.data or not db.data.rows then
    return
  end
  local cx, cy = getCursorPosition()
  if not cx then
    db.data.hovered_row = false
    return
  end
  local ax, ay = cx * sx, cy * sy
  local d = db.dimensions
  local ch = db.properties.column_height.value
  local rw = db.data.scrollbar and d.width - 10 or d.width
  db.data.hovered_row = false
  for i = db.data.row_i, db.data.row_f do
    local cell = db.data.rows[i] and db.data.rows[i][1]
    if cell then
      local ry = d.y + 2 + ch + cell.height * (i - db.data.row_i)
      if ax >= d.x and ay >= ry and ax <= d.x + rw and ay <= ry + cell.height then
        db.data.hovered_row = i - 1
      end
    end
  end
end
function UI.refreshMenuHoverRow(arg0)
  local db = UI.DB[arg0]
  if not db or not db.data or not db.data.rows then
    return
  end
  local cx, cy = getCursorPosition()
  if not cx then
    db.data.hovered_row = false
    return
  end
  local ax, ay = cx * sx, cy * sy
  local d = db.dimensions
  local rw = db.data.scrollbar and d.width - 10 or d.width
  db.data.hovered_row = false
  for i = db.data.row_i, db.data.row_f do
    local row = db.data.rows[i]
    if row then
      local ry = d.y + 5 + (row.height * SCALE_Y + 4) * (i - db.data.row_i)
      local rh = row.height * SCALE_Y
      if ax >= d.x + 5 and ay >= ry and ax <= d.x + 5 + rw and ay <= ry + rh then
        db.data.hovered_row = i
      end
    end
  end
end
-- [Fix #87] the menu click path only fires when UI.HoveredElement IS the
-- menu; when any other element draws above it (the classic case: the
-- alpha-0 main-menu window rectangle acting as a hit target), sidebar rows
-- looked dead while the menu still rendered normally. Resolve the topmost
-- MENU under the cursor directly as a fallback.
local function menuUnderCursor()
  local cx, cy = getCursorPosition()
  if not cx then
    return false
  end
  cx, cy = cx * sx, cy * sy
  for i = #UI.DrawElements, 1, -1 do
    local el = UI.DrawElements[i]
    if (UI.EType[el] or getElementType(el)) == "ui-menu" and UI.DB[el]
      and UI.DB[el].visible and UI.isDraw[el] and not isUIDisabled(el) then
      local d = UI.DB[el].dimensions
      if d and cx >= d.x and cy >= d.y and cx <= d.x + d.width and cy <= d.y + d.height then
        return el
      end
    end
  end
  return false
end
function UI.click(arg0, arg1, arg2, arg3)
  -- [Vortex fix #12] fresh hover at click time (kills the stale-frame gap)
  UI.HoveredElement = UI.refreshHover() or false
  -- [Fix #87] if hover resolved to something that is NOT the menu under the
  -- cursor (window chrome / overlay above the sidebar), prefer the menu so
  -- sidebar row selection keeps working. The menu's own scrollbar keeps
  -- priority (it is a child drawn above the menu rect).
  if not isUIElement(UI.HoveredElement, "menu") then
    local m = menuUnderCursor()
    if m and UI.HoveredElement ~= UI.DB[m].data.scrollbar then
      UI.HoveredElement = m
    end
  end
  if arg0 == "left" then
    if UI.HoveredElement then
      if clickTimer1 and isTimer(clickTimer1) then
        killTimer(clickTimer1)
      end
      if clickTimer2 and isTimer(clickTimer2) then
        killTimer(clickTimer2)
      end
      if isUIDisabled(UI.HoveredElement) then
        return
      end
      if isElement(UI.FocusElement) then
        UI.DB[UI.FocusElement].state = "normal"
        if UI.FocusElement ~= UI.HoveredElement then
          triggerEvent("onClientUIBlur", UI.FocusElement)
        end
      end
      if UI.FocusElement ~= UI.HoveredElement then
        triggerEvent("onClientUIFocus", UI.HoveredElement)
      end
      UI.FocusElement = UI.HoveredElement
      if arg0 == "left" then
        if arg1 == "up" then
          if getElementType(UI.HoveredElement) == "ui-edit" then
            if arg2 > UI.DB[UI.HoveredElement].dimensions.x + 7 + dxGetTextWidth(UI.DB[UI.HoveredElement].text, UI.DB[UI.HoveredElement].font.size, UI.DB[UI.HoveredElement].font.name) then
              uiEditSetCaretIndex(UI.HoveredElement, utfLen(UI.DB[UI.HoveredElement].text) + 1)
            elseif arg2 < UI.DB[UI.HoveredElement].dimensions.x + 7 then
              uiEditSetCaretIndex(UI.HoveredElement, 1)
            else
              for forvar12 = 1, utfLen(UI.DB[UI.HoveredElement].text) do
                if arg2 >= UI.DB[UI.HoveredElement].dimensions.x + 7 + dxGetTextWidth(utfSub(UI.DB[UI.HoveredElement].text, 1, forvar12 - 1), UI.DB[UI.HoveredElement].font.size, UI.DB[UI.HoveredElement].font.name) and arg2 <= UI.DB[UI.HoveredElement].dimensions.x + 7 + dxGetTextWidth(utfSub(UI.DB[UI.HoveredElement].text, 1, forvar12), UI.DB[UI.HoveredElement].font.size, UI.DB[UI.HoveredElement].font.name) then
                  uiEditSetCaretIndex(UI.HoveredElement, forvar12 + 1)
                  break
                end
              end
            end
            removeEventHandler("onClientCursorMove", root, moveCursor)
            toggleControl("chatbox", false)
          elseif getElementType(UI.HoveredElement) == "ui-combobox" then
            if isMouseInPosition(UI.DB[UI.HoveredElement].dimensions.x + (UI.DB[UI.HoveredElement].dimensions.width - UI.DB[UI.HoveredElement].dimensions.width / 8), UI.DB[UI.HoveredElement].dimensions.y, UI.DB[UI.HoveredElement].dimensions.width / 8, UI.DB[UI.HoveredElement].dimensions.height) then
              UI.DB[UI.HoveredElement].data.visible = not UI.DB[UI.HoveredElement].data.visible
              uiSetVisible(UI.DB[UI.HoveredElement].scrollbar.element, #UI.DB[UI.HoveredElement].data.items > UI.DB[UI.HoveredElement].properties.items_per_page.value and not UI.DB[UI.HoveredElement].data.visible or false)
              UI.VisibleList = UI.HoveredElement
              uiBringToFront(UI.HoveredElement)
            end
          elseif getElementType(UI.HoveredElement) == "ui-switch" or getElementType(UI.HoveredElement) == "ui-checkbox" then
            UI.DB[UI.HoveredElement].data.selected = not UI.DB[UI.HoveredElement].data.selected
            UI.DB[UI.HoveredElement].animation[1] = getTickCount()
            playSound(":UIKit/sounds/click2.wav")
          elseif getElementType(UI.HoveredElement) == "ui-radiobutton" then
            if UI.HoveredElement ~= UI.SelectedRadio[getElementType(UI.HoveredElement)] and UI.SelectedRadio[getElementType(UI.HoveredElement)] then
              UI.DB[UI.SelectedRadio[getElementType(UI.HoveredElement)]].animation[1] = getTickCount()
            end
            UI.DB[UI.HoveredElement].animation[1] = getTickCount()
            UI.SelectedRadio[getElementType(UI.HoveredElement)] = UI.SelectedRadio[getElementType(UI.HoveredElement)] ~= UI.HoveredElement and UI.HoveredElement
          elseif getElementType(UI.HoveredElement) == "ui-memo" then
            removeEventHandler("onClientCursorMove", root, moveCursorForShading)
            toggleControl("chatbox", false)
          elseif getElementType(UI.HoveredElement) == "ui-window" or getElementType(UI.HoveredElement) == "ui-dialog" then
            removeEventHandler("onClientCursorMove", root, moveElement)
            moveTemp = {}
          elseif getElementType(UI.HoveredElement) == "ui-tabpanel" and UI.DB[UI.HoveredElement].data.hovered_tab and UI.DB[UI.DB[UI.HoveredElement].data.hovered_tab].properties.Disabled.value ~= "True" and UI.DB[UI.HoveredElement].properties.Disabled.value ~= "True" and UI.DB[UI.HoveredElement].data.selected_tab ~= UI.DB[UI.HoveredElement].data.hovered_tab then
            uiSetSelectedTab(UI.HoveredElement, UI.DB[UI.HoveredElement].data.hovered_tab)
          end
          if UI.DraggedElement then
            removeEventHandler("onClientCursorMove", root, dragElement)
            if dragTemp then
              local dcx, dcy, dox, doy = unpack(dragTemp)
              UI.DB[UI.DraggedElement].dimensions.x = dox
              UI.DB[UI.DraggedElement].dimensions.y = doy
            end
            triggerEvent("onClientUIDragEnd", UI.DraggedElement, UI.HoveredElement)
            UI.DraggedElement = nil
          end
        else
          if getElementType(UI.HoveredElement) == "ui-gridlist" then
            -- [Vortex fix #12] drawn hovered_row is stale in the click gap
            UI.refreshGridlistHoverRow(UI.HoveredElement)
            if not UI.DB[UI.HoveredElement].data.hovered_row then
              UI.DB[UI.HoveredElement].data.selected_row = -1
              triggerEvent("onClientUIGridlistItemSelected", UI.HoveredElement, UI.DB[UI.HoveredElement].data.selected_row)
            elseif UI.DB[UI.HoveredElement].data.selected_row ~= UI.DB[UI.HoveredElement].data.hovered_row then
              UI.DB[UI.HoveredElement].data.selected_row = UI.DB[UI.HoveredElement].data.hovered_row
              UI.DB[UI.HoveredElement].data.selection_tick = getTickCount()
              triggerEvent("onClientUIGridlistItemSelected", UI.HoveredElement, UI.DB[UI.HoveredElement].data.selected_row)
            end
          elseif getElementType(UI.HoveredElement) == "ui-checklist" then
            if UI.DB[UI.HoveredElement].data.hovered_row and UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row] then
              UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].selected = not UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].selected
              UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].animation[1] = getTickCount()
            end
          elseif getElementType(UI.HoveredElement) == "ui-menu" then
            -- [Vortex fix #12] drawn hovered_row is stale in the click gap
            UI.refreshMenuHoverRow(UI.HoveredElement)
            if UI.DB[UI.HoveredElement].data.hovered_row and UI.DB[UI.HoveredElement].data.selected_row ~= UI.DB[UI.HoveredElement].data.hovered_row then
              -- [Vortex fix] decompiler moved the selected_row assignment above
              -- the hide block, so the OLD row was never hidden (sections stacked
              -- on each other). Hide the OLD toggle element BEFORE reassigning.
              if UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.selected_row] and UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.selected_row].toggle_element then
                uiSetVisible(UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.selected_row].toggle_element, false)
              end
              UI.DB[UI.HoveredElement].data.selected_row = UI.DB[UI.HoveredElement].data.hovered_row
              if UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row] and UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].toggle_element then
                uiSetVisible(UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].toggle_element, true)
              end
              triggerEvent("onClientUIMenuSelectChange", UI.HoveredElement, UI.DB[UI.HoveredElement].data.hovered_row, UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row] and UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].toggle_element)
            end
          elseif isElement(UI.VisibleList) and getElementType(UI.VisibleList) == "ui-combobox" and UI.HoveredElement ~= UI.DB[UI.VisibleList].scrollbar.element and not UI.DB[UI.VisibleList].data.hovered_item then
            if not isMouseInPosition(UI.DB[UI.VisibleList].dimensions.x + (UI.DB[UI.VisibleList].dimensions.width - UI.DB[UI.VisibleList].dimensions.width / 8), UI.DB[UI.VisibleList].dimensions.y, UI.DB[UI.VisibleList].dimensions.width / 8, UI.DB[UI.VisibleList].dimensions.height) and UI.DB[UI.VisibleList].data.visible then
              UI.DB[UI.VisibleList].data.visible = false
              UI.DB[UI.VisibleList].data.selected_item = -1
              uiSetVisible(UI.DB[UI.VisibleList].scrollbar.element, false)
              UI.VisibleList = false
            end
          elseif getElementType(UI.HoveredElement) == "ui-scrollbar" then
            if UI.DB[UI.HoveredElement].data.horizontal then
              if arg2 >= UI.DB[UI.HoveredElement].data.scrollX and arg2 <= UI.DB[UI.HoveredElement].data.scrollX + UI.DB[UI.HoveredElement].properties.thumb_size.value then
                UI.DB[UI.HoveredElement].data.clickPositionRelatedToScroll = arg2 - UI.DB[UI.HoveredElement].data.scrollX
              else
                UI.DB[UI.HoveredElement].data.scrollX = arg2
                UI.DB[UI.HoveredElement].data.scrollX = math.min(math.max(UI.DB[UI.HoveredElement].dimensions.x + 1, UI.DB[UI.HoveredElement].data.scrollX), UI.DB[UI.HoveredElement].dimensions.x + UI.DB[UI.HoveredElement].dimensions.width - UI.DB[UI.HoveredElement].properties.thumb_size.value - 1)
              end
            elseif arg3 >= UI.DB[UI.HoveredElement].data.scrollY and arg3 <= UI.DB[UI.HoveredElement].data.scrollY + UI.DB[UI.HoveredElement].properties.thumb_size.value then
              UI.DB[UI.HoveredElement].data.clickPositionRelatedToScroll = arg3 - UI.DB[UI.HoveredElement].data.scrollY
            else
              UI.DB[UI.HoveredElement].data.scrollY = arg3
              UI.DB[UI.HoveredElement].data.scrollY = math.min(math.max(UI.DB[UI.HoveredElement].dimensions.y + 1, UI.DB[UI.HoveredElement].data.scrollY), UI.DB[UI.HoveredElement].dimensions.y + UI.DB[UI.HoveredElement].dimensions.height - UI.DB[UI.HoveredElement].properties.thumb_size.value - 1)
            end
          elseif getElementType(UI.HoveredElement) == "ui-edit" then
            UI.DB[UI.HoveredElement].data.shading[1] = getCaretFromCursorPosition(UI.DB[UI.HoveredElement].dimensions.x + 7, UI.DB[UI.HoveredElement].text, arg2, UI.HoveredElement)
            UI.DB[UI.HoveredElement].data.shading[2] = getCaretFromCursorPosition(UI.DB[UI.HoveredElement].dimensions.x + 7, UI.DB[UI.HoveredElement].text, arg2, UI.HoveredElement)
            UI.DB[UI.HoveredElement].data.shading[3] = getCaretFromCursorPosition(UI.DB[UI.HoveredElement].dimensions.x + 7, UI.DB[UI.HoveredElement].text, arg2, UI.HoveredElement)
            addEventHandler("onClientCursorMove", root, moveCursor)
            toggleControl("chatbox", false)
          elseif getElementType(UI.HoveredElement) == "ui-memo" then
            if getKeyState("lshift") or getKeyState("rshift") then
              if UI.DB[UI.HoveredElement].data.caretLine == getLineFromCursorPosition(UI.HoveredElement, arg3) then
                UI.DB[UI.HoveredElement].data.shadingTable[1][3] = getCaretFromCursorPosition(UI.DB[UI.HoveredElement].dimensions.x + 7, (UI.DB[UI.HoveredElement].text:find("\n", 1, true) and split(UI.DB[UI.HoveredElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                  UI.DB[UI.HoveredElement].text
                })[getLineFromCursorPosition(UI.HoveredElement, arg3)]:gsub("" .. newLinePrefix, ""), arg2, UI.HoveredElement)
                UI.DB[UI.HoveredElement].data.shadingTable[2] = UI.DB[UI.HoveredElement].data.shadingTable[1]
              else
                UI.DB[UI.HoveredElement].data.shadingTable[1][3] = utfLen((UI.DB[UI.HoveredElement].text:find("\n", 1, true) and split(UI.DB[UI.HoveredElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                  UI.DB[UI.HoveredElement].text
                })[UI.DB[UI.HoveredElement].data.shadingTable[1][1]]:gsub("" .. newLinePrefix, "")) + 1
                UI.DB[UI.HoveredElement].data.shadingTable[2] = {
                  getLineFromCursorPosition(UI.HoveredElement, arg3),
                  1,
                  (getCaretFromCursorPosition(UI.DB[UI.HoveredElement].dimensions.x + 7, (UI.DB[UI.HoveredElement].text:find("\n", 1, true) and split(UI.DB[UI.HoveredElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                    UI.DB[UI.HoveredElement].text
                  })[getLineFromCursorPosition(UI.HoveredElement, arg3)]:gsub("" .. newLinePrefix, ""), arg2, UI.HoveredElement))
                }
              end
            else
              UI.DB[UI.HoveredElement].data.shadingTable[1] = {
                getLineFromCursorPosition(UI.HoveredElement, arg3),
                getCaretFromCursorPosition(UI.DB[UI.HoveredElement].dimensions.x + 7, (UI.DB[UI.HoveredElement].text:find("\n", 1, true) and split(UI.DB[UI.HoveredElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                  UI.DB[UI.HoveredElement].text
                })[getLineFromCursorPosition(UI.HoveredElement, arg3)]:gsub("" .. newLinePrefix, ""), arg2, UI.HoveredElement),
                (getCaretFromCursorPosition(UI.DB[UI.HoveredElement].dimensions.x + 7, (UI.DB[UI.HoveredElement].text:find("\n", 1, true) and split(UI.DB[UI.HoveredElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                  UI.DB[UI.HoveredElement].text
                })[getLineFromCursorPosition(UI.HoveredElement, arg3)]:gsub("" .. newLinePrefix, ""), arg2, UI.HoveredElement))
              }
              UI.DB[UI.HoveredElement].data.shadingTable[2] = UI.DB[UI.HoveredElement].data.shadingTable[1]
            end
            UI.DB[UI.HoveredElement].data.caretLine = getLineFromCursorPosition(UI.HoveredElement, arg3)
            UI.DB[UI.HoveredElement].data.caret = getCaretFromCursorPosition(UI.DB[UI.HoveredElement].dimensions.x + 7, (UI.DB[UI.HoveredElement].text:find("\n", 1, true) and split(UI.DB[UI.HoveredElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
              UI.DB[UI.HoveredElement].text
            })[getLineFromCursorPosition(UI.HoveredElement, arg3)]:gsub("" .. newLinePrefix, ""), arg2, UI.HoveredElement)
            if uiMemoGetCaretIndex(UI.HoveredElement) ~= uiMemoGetCaretIndex(UI.HoveredElement) then
              triggerEvent("onClientUICaretPositionChange", UI.HoveredElement, uiMemoGetCaretIndex(UI.HoveredElement))
            end
            addEventHandler("onClientCursorMove", root, moveCursorForShading)
            toggleControl("chatbox", false)
          elseif (getElementType(UI.HoveredElement) == "ui-window" or getElementType(UI.HoveredElement) == "ui-dialog") and arg1 == "down" and UI.DB[UI.HoveredElement].properties.movable.value then
            moveTemp = {
              arg2,
              arg3,
              uiGetPosition(UI.HoveredElement)
            }
            addEventHandler("onClientCursorMove", root, moveElement)
          end
          if not UI.DraggedElement and UI.DB[UI.HoveredElement].properties.draggable and UI.DB[UI.HoveredElement].properties.draggable.value then
            uiDragElement(UI.HoveredElement)
          end
        end
      end
      -- [Vortex fix #12+#14] audible + visual acknowledgement: the flash is
      -- driven by press_tick stamped here and drawn by the button
      if arg1 == "down" and getElementType(UI.HoveredElement) == "ui-button" then
        playSound(":UIKit/sounds/click.wav")
        UI.DB[UI.HoveredElement].press_tick = getTickCount()
      end
      if arg1 == "down" and UI.DB[UI.HoveredElement].properties.DisableFocus.value ~= "False" then
        uiBringToFront(UI.HoveredElement)
      end
      UI.DB[UI.HoveredElement].state = arg1 == "down" and "clicked" or UI.DB[UI.HoveredElement].state
      -- [Vortex fix #14] release the pressed look on mouse-up (it used to stay
      -- "clicked" forever until the next click - and the decompiled edge-case
      -- reset in the draw loop killed the feedback after a single frame)
      if arg1 == "up" and getElementType(UI.HoveredElement) == "ui-button" then
        UI.DB[UI.HoveredElement].state = "normal"
      end
      triggerEvent(arg1 == "up" and "onClientUIClick" or "onClientUIStartClick", UI.HoveredElement, arg2, arg3)
    else
      if UI.FocusElement then
        UI.DB[UI.FocusElement].state = "normal"
        triggerEvent("onClientUIBlur", UI.FocusElement)
      end
      UI.FocusElement = false
    end
  elseif arg0 == "right" and not UI.HoveredElement then
    if UI.FocusElement then
      UI.DB[UI.FocusElement].state = "normal"
      triggerEvent("onClientUIBlur", UI.FocusElement)
    end
    UI.FocusElement = false
  end
end
addEventHandler("onClientClick", root, UI.click)

-- [Fix #14] cross-resource press feedback: resources that dispatch clicks
-- themselves (the raw hit-registry layer) call this to flash a button
function uiFlashPress(el)
        if not (el and isElement(el) and UI.DB[el]) then return false end
        if getElementType(el) ~= "ui-button" then return false end
        UI.DB[el].state = "clicked"
        UI.DB[el].press_tick = getTickCount()
        setTimer(function(e)
                if isElement(e) and UI.DB[e] then
                        UI.DB[e].state = "normal"
                end
        end, 130, 1, el)
        return true
end
function UI.doubleclick(arg0, arg1, arg2)
  -- [Vortex fix #12] fresh hover here too
  UI.HoveredElement = UI.refreshHover() or false
  if arg0 == "left" and UI.HoveredElement then
    if isUIDisabled(UI.HoveredElement) then
      return
    end
    if getElementType(UI.HoveredElement) == "ui-edit" then
      UI.DB[UI.HoveredElement].data.shading[1] = 1
      UI.DB[UI.HoveredElement].data.shading[2] = utfLen(UI.DB[UI.HoveredElement].text) + 1
      UI.DB[UI.HoveredElement].data.shading[3] = 1
      uiEditSetCaretIndex(UI.HoveredElement, utfLen(UI.DB[UI.HoveredElement].text) + 1)
    elseif getElementType(UI.HoveredElement) == "ui-memo" then
      UI.DB[UI.HoveredElement].data.shadingTable[1] = {
        getLineFromCursorPosition(UI.HoveredElement, arg2),
        1,
        utfLen((UI.DB[UI.HoveredElement].text:find("\n", 1, true) and split(UI.DB[UI.HoveredElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.HoveredElement].text
        })[getLineFromCursorPosition(UI.HoveredElement, arg2)]:gsub("" .. newLinePrefix, "")) + 1
      }
      UI.DB[UI.HoveredElement].data.shadingTable[2] = UI.DB[UI.HoveredElement].data.shadingTable[1]
      UI.DB[UI.HoveredElement].data.caretLine = getLineFromCursorPosition(UI.HoveredElement, arg2)
      UI.DB[UI.HoveredElement].data.caret = utfLen((UI.DB[UI.HoveredElement].text:find("\n", 1, true) and split(UI.DB[UI.HoveredElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
        UI.DB[UI.HoveredElement].text
      })[getLineFromCursorPosition(UI.HoveredElement, arg2)]:gsub("" .. newLinePrefix, "")) + 1
      if uiMemoGetCaretIndex(UI.HoveredElement) ~= uiMemoGetCaretIndex(UI.HoveredElement) then
        triggerEvent("onClientUICaretPositionChange", UI.HoveredElement, uiMemoGetCaretIndex(UI.HoveredElement))
      end
    end
    triggerEvent("onClientUIDoubleClick", UI.HoveredElement, arg1, arg2)
  end
end
addEventHandler("onClientDoubleClick", root, UI.doubleclick)
addEventHandler("onClientCharacter", root, function(arg0)
  if UI.FocusElement and getElementType(UI.FocusElement) == "ui-edit" and not UI.DB[UI.FocusElement].data.readonly then
    if not isTypableCharacter(arg0) then
      return
    end
    if uiEditGetShadedText(UI.FocusElement) then
      -- [Fix #76] same reset-before-use bug as removeText: capture the
      -- selection first, otherwise the typed char was inserted against the
      -- already-reset {1,1} shading (prepended to the full text)
      local sh1, sh2 = UI.DB[UI.FocusElement].data.shading[1], UI.DB[UI.FocusElement].data.shading[2]
      UI.DB[UI.FocusElement].data.shading = {1, 1}
      uiSetText(UI.FocusElement, utfSub(UI.DB[UI.FocusElement].text, 1, sh1 - 1) .. arg0 .. utfSub(UI.DB[UI.FocusElement].text, sh2, utfLen(UI.DB[UI.FocusElement].text)))
      triggerEvent("onClientUIChanged", UI.FocusElement)
      uiEditSetCaretIndex(UI.FocusElement, utfLen(utfSub(UI.DB[UI.FocusElement].text, 1, sh1 - 1) .. arg0) + 1)
    else
      if UI.DB[UI.FocusElement].data.maxlength ~= -1 and utfLen(utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.caret - 1) .. arg0 .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.caret, utfLen(UI.DB[UI.FocusElement].text))) > UI.DB[UI.FocusElement].data.maxlength then
        uiSetText(UI.FocusElement, utfSub(utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.caret - 1) .. arg0 .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.caret, utfLen(UI.DB[UI.FocusElement].text)), 1, UI.DB[UI.FocusElement].data.maxlength))
        uiEditSetCaretIndex(UI.FocusElement, math.min(UI.DB[UI.FocusElement].data.caret + utfLen(arg0), UI.DB[UI.FocusElement].data.maxlength + 1))
      else
        uiSetText(UI.FocusElement, utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.caret - 1) .. arg0 .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.caret, utfLen(UI.DB[UI.FocusElement].text)))
        uiEditSetCaretIndex(UI.FocusElement, utfLen(utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.caret - 1) .. arg0) + 1)
      end
      triggerEvent("onClientUIChanged", UI.FocusElement)
    end
  elseif UI.FocusElement and getElementType(UI.FocusElement) == "ui-memo" and not UI.DB[UI.FocusElement].data.readonly then
    if not isTypableCharacter(arg0) then
      return
    end
    if replaceShadedText(UI.FocusElement, arg0) then
      triggerEvent("onClientUITextChange", UI.FocusElement)
      return
    end
    -- [Fix #82] build the new text in ONE local line table; the decompiled
    -- form assigned into a temporary returned by split() and then wrote back
    -- a fresh concat of the UNCHANGED original text, so the typed character
    -- was constructed and thrown away (the report memo accepted no letters)
    local memoDb = UI.DB[UI.FocusElement]
    local memoLines = memoSplitLines(memoDb.text)
    local memoLine = math.max(1, math.min(memoDb.data.caretLine or 1, #memoLines))
    local memoText = (memoLines[memoLine] or ""):gsub(newLinePrefix, "")
    memoLines[memoLine] = utfSub(memoText, 1, memoDb.data.caret - 1) .. arg0 .. utfSub(memoText, memoDb.data.caret, utfLen(memoText))
    memoSetText(UI.FocusElement, memoJoinLines(memoLines))
    memoDb.data.caret = memoDb.data.caret + utfLen(arg0)
    triggerEvent("onClientUICaretPositionChange", UI.FocusElement, uiMemoGetCaretIndex(UI.FocusElement))
  end
end)
addEvent("ui-returnClipBoard", true)
addEventHandler("ui-returnClipBoard", localPlayer, function(arg0)
  if UI.FocusElement and getElementType(UI.FocusElement) == "ui-edit" and not UI.DB[UI.FocusElement].data.readonly then
    arg0 = arg0:gsub("\n", "")
    if uiEditGetShadedText(UI.FocusElement) then
    end
    if UI.DB[UI.FocusElement].data.maxlength ~= -1 and utfLen(utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.shading[1] - 1) .. arg0 .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.shading[2], utfLen(UI.DB[UI.FocusElement].text))) > UI.DB[UI.FocusElement].data.maxlength then
      uiSetText(UI.FocusElement, utfSub(utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.shading[1] - 1) .. arg0 .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.shading[2], utfLen(UI.DB[UI.FocusElement].text)), 1, UI.DB[UI.FocusElement].data.maxlength))
      uiEditSetCaretIndex(UI.FocusElement, math.min(UI.DB[UI.FocusElement].data.caret + utfLen(arg0), UI.DB[UI.FocusElement].data.maxlength + 1))
    else
      uiSetText(UI.FocusElement, utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.shading[1] - 1) .. arg0 .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.shading[2], utfLen(UI.DB[UI.FocusElement].text)))
      uiEditSetCaretIndex(UI.FocusElement, utfLen(utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.shading[1] - 1) .. arg0) + 1)
    end
    triggerEvent("onClientUIChanged", UI.FocusElement)
    UI.DB[UI.FocusElement].data.shading = {1, 1}
  elseif UI.FocusElement and getElementType(UI.FocusElement) == "ui-memo" and not UI.DB[UI.FocusElement].data.readonly then
    arg0 = arg0:gsub("" .. newLinePrefix, "\n")
    if replaceShadedText(UI.FocusElement, arg0) then
      triggerEvent("onClientUITextChange", UI.FocusElement)
      return
    end
    -- [Fix #82] same temp-table discard as the character insert above:
    -- paste built the new line in a throwaway split() table, then wrote the
    -- unchanged original back, so clipboard text never reached the memo
    local memoDb = UI.DB[UI.FocusElement]
    local memoLines = memoSplitLines(memoDb.text)
    local memoLine = math.max(1, math.min(memoDb.data.caretLine or 1, #memoLines))
    local memoText = (memoLines[memoLine] or ""):gsub(newLinePrefix, "")
    local memoBefore = utfSub(memoText, 1, memoDb.data.caret - 1)
    memoLines[memoLine] = memoBefore .. arg0 .. utfSub(memoText, memoDb.data.caret, utfLen(memoText))
    memoSetText(UI.FocusElement, memoJoinLines(memoLines))
    local memoInserted = memoBefore .. arg0
    local memoNewLines = select(2, memoInserted:gsub("\n", "\n"))
    if memoNewLines > 0 then
      memoDb.data.caretLine = memoLine + memoNewLines
      memoDb.data.caret = utfLen(memoInserted:match("[^\n]*$") or "") + 1
    else
      memoDb.data.caret = utfLen(memoInserted) + 1
    end
    triggerEvent("onClientUICaretPositionChange", UI.FocusElement, uiMemoGetCaretIndex(UI.FocusElement))
  end
end)
function moveCaret(arg0, arg1)
  if UI.FocusElement and getElementType(UI.FocusElement) == "ui-edit" then
    if arg1 == "down" then
      if arg0 == "arrow_r" then
        uiEditSetCaretIndex(UI.FocusElement, math.min(UI.DB[UI.FocusElement].data.caret + 1, utfLen(UI.DB[UI.FocusElement].text) + 1))
        if repeatTimer and isTimer(repeatTimer) then
          killTimer(repeatTimer)
        end
        repeatTimer = setTimer(function(arg0)
          uiEditSetCaretIndex(arg0, math.min(UI.DB[arg0].data.caret + 1, utfLen(UI.DB[arg0].text) + 1))
        end, 150, 0, UI.FocusElement)
      elseif arg0 == "arrow_l" then
        uiEditSetCaretIndex(UI.FocusElement, math.max(UI.DB[UI.FocusElement].data.caret - 1, 1))
        if repeatTimer and isTimer(repeatTimer) then
          killTimer(repeatTimer)
        end
        repeatTimer = setTimer(function(arg0)
          uiEditSetCaretIndex(arg0, math.max(UI.DB[arg0].data.caret - 1, 1))
        end, 150, 0, UI.FocusElement)
      end
    elseif repeatTimer and isTimer(repeatTimer) then
      killTimer(repeatTimer)
    end
  elseif UI.FocusElement and getElementType(UI.FocusElement) == "ui-memo" then
    if arg1 == "down" then
      if arg0 == "arrow_r" then
        UI.DB[UI.FocusElement].data.caret = math.min(UI.DB[UI.FocusElement].data.caret + 1, utfLen(((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""))) + 1)
        if repeatTimer and isTimer(repeatTimer) then
          killTimer(repeatTimer)
        end
        local lineText = ((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        })[UI.DB[UI.FocusElement].data.caretLine] or ""):gsub("" .. newLinePrefix, "")
        repeatTimer = setTimer(function(arg0)
          UI.DB[arg0].data.caret = math.min(UI.DB[arg0].data.caret + 1, utfLen(lineText) + 1)
          if uiMemoGetCaretIndex(arg0) ~= uiMemoGetCaretIndex(arg0) then
            triggerEvent("onClientUICaretPositionChange", arg0, uiMemoGetCaretIndex(arg0))
          end
        end, 150, 0, UI.FocusElement)
      elseif arg0 == "arrow_l" then
        UI.DB[UI.FocusElement].data.caret = math.max(UI.DB[UI.FocusElement].data.caret - 1, 1)
        if repeatTimer and isTimer(repeatTimer) then
          killTimer(repeatTimer)
        end
        repeatTimer = setTimer(function(arg0)
          UI.DB[arg0].data.caret = math.max(UI.DB[arg0].data.caret - 1, 1)
          if uiMemoGetCaretIndex(arg0) ~= uiMemoGetCaretIndex(arg0) then
            triggerEvent("onClientUICaretPositionChange", arg0, uiMemoGetCaretIndex(arg0))
          end
        end, 150, 0, UI.FocusElement)
      elseif arg0 == "arrow_u" then
        UI.DB[UI.FocusElement].data.caretLine = math.max(UI.DB[UI.FocusElement].data.caretLine - 1, 1)
        if repeatTimer and isTimer(repeatTimer) then
          killTimer(repeatTimer)
        end
        repeatTimer = setTimer(function(arg0)
          UI.DB[arg0].data.caretLine = math.max(UI.DB[arg0].data.caretLine - 1, 1)
          if uiMemoGetCaretIndex(arg0) ~= uiMemoGetCaretIndex(arg0) then
            triggerEvent("onClientUICaretPositionChange", arg0, uiMemoGetCaretIndex(arg0))
          end
        end, 150, 0, UI.FocusElement)
      elseif arg0 == "arrow_d" then
        UI.DB[UI.FocusElement].data.caretLine = math.min(UI.DB[UI.FocusElement].data.caretLine + 1, #(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }))
        if repeatTimer and isTimer(repeatTimer) then
          killTimer(repeatTimer)
        end
        local linesTable = UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }
        repeatTimer = setTimer(function(arg0)
          UI.DB[arg0].data.caretLine = math.min(UI.DB[arg0].data.caretLine + 1, #linesTable)
          if uiMemoGetCaretIndex(arg0) ~= uiMemoGetCaretIndex(arg0) then
            triggerEvent("onClientUICaretPositionChange", arg0, uiMemoGetCaretIndex(arg0))
          end
        end, 150, 0, UI.FocusElement)
      end
      if uiMemoGetCaretIndex(UI.FocusElement) ~= uiMemoGetCaretIndex(UI.FocusElement) then
        triggerEvent("onClientUICaretPositionChange", UI.FocusElement, uiMemoGetCaretIndex(UI.FocusElement))
      end
    elseif repeatTimer and isTimer(repeatTimer) then
      killTimer(repeatTimer)
    end
  end
end
bindKey("arrow_r", "both", handleTextKey)
bindKey("arrow_l", "both", handleTextKey)
bindKey("arrow_u", "both", handleTextKey)
bindKey("arrow_d", "both", handleTextKey)
function removeText(arg0, arg1)
  if UI.FocusElement and getElementType(UI.FocusElement) == "ui-edit" and not UI.DB[UI.FocusElement].data.readonly then
    if UI.DB[UI.FocusElement].text then
      if arg1 == "down" then
        if uiEditGetShadedText(UI.FocusElement) then
          -- [Fix #76] capture the selection BEFORE resetting it: the old code
          -- reset shading to {1,1} first and then sliced with the reset values,
          -- so backspace on a selection deleted NOTHING and pinned the caret at
          -- 1 (deletion looked dead in every panel once text was selected)
          local sh1, sh2 = UI.DB[UI.FocusElement].data.shading[1], UI.DB[UI.FocusElement].data.shading[2]
          UI.DB[UI.FocusElement].data.shading = {1, 1}
          uiSetText(UI.FocusElement, utfSub(UI.DB[UI.FocusElement].text, 1, sh1 - 1) .. utfSub(UI.DB[UI.FocusElement].text, sh2, utfLen(UI.DB[UI.FocusElement].text)))
          uiEditSetCaretIndex(UI.FocusElement, sh1)
          triggerEvent("onClientUIChanged", UI.FocusElement)
        elseif arg0 == "backspace" then
          uiSetText(UI.FocusElement, utfSub(UI.DB[UI.FocusElement].text, 1, math.max(0, UI.DB[UI.FocusElement].data.caret - 2)) .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.caret, utfLen(UI.DB[UI.FocusElement].text)))
          uiEditSetCaretIndex(UI.FocusElement, math.max(1, UI.DB[UI.FocusElement].data.caret - 1))
          triggerEvent("onClientUIChanged", UI.FocusElement)
          if repeatTimer and isTimer(repeatTimer) then
            killTimer(repeatTimer)
          end
          repeatCount = 0
          repeatTimer = setTimer(function(arg0)
            repeatCount = repeatCount + 1
            if repeatCount >= 5 then
              uiSetText(arg0, utfSub(UI.DB[arg0].text, 1, math.max(0, UI.DB[arg0].data.caret - 2)) .. utfSub(UI.DB[arg0].text, UI.DB[arg0].data.caret, utfLen(UI.DB[arg0].text)))
              uiEditSetCaretIndex(arg0, math.max(1, UI.DB[arg0].data.caret - 1))
              triggerEvent("onClientUIChanged", arg0)
            end
          end, 80, 0, UI.FocusElement)
        elseif arg0 == "delete" then
          uiSetText(UI.FocusElement, utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.caret - 1) .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.caret + 1, utfLen(UI.DB[UI.FocusElement].text)))
          triggerEvent("onClientUIChanged", UI.FocusElement)
          if repeatTimer and isTimer(repeatTimer) then
            killTimer(repeatTimer)
          end
          repeatCount = 0
          repeatTimer = setTimer(function(arg0)
            repeatCount = repeatCount + 1
            if repeatCount >= 5 then
              uiSetText(arg0, utfSub(UI.DB[arg0].text, 1, UI.DB[arg0].data.caret - 1) .. utfSub(UI.DB[arg0].text, UI.DB[arg0].data.caret + 1, utfLen(UI.DB[arg0].text)))
              triggerEvent("onClientUIChanged", arg0)
            end
          end, 80, 0, UI.FocusElement)
        end
      elseif repeatTimer and isTimer(repeatTimer) then
        killTimer(repeatTimer)
      end
    end
  elseif UI.FocusElement and getElementType(UI.FocusElement) == "ui-memo" and not UI.DB[UI.FocusElement].data.readonly and UI.DB[UI.FocusElement].text then
    if arg1 == "down" then
      if replaceShadedText(UI.FocusElement, "") then
        triggerEvent("onClientUITextChange", UI.FocusElement)
        return
      end
      if arg0 == "backspace" or arg0 == "delete" then
        -- [Fix #82] the decompiled block mutated a throwaway table returned
        -- by split() and concatenated the UNCHANGED original text, so
        -- backspace/delete in a memo (report box) removed nothing at all
        local memoEl = UI.FocusElement
        local repeatKey = arg0
        memoDeleteChar(memoEl, repeatKey)
        if repeatTimer and isTimer(repeatTimer) then
          killTimer(repeatTimer)
        end
        repeatCount = 0
        repeatTimer = setTimer(function(el)
          repeatCount = repeatCount + 1
          if repeatCount >= 5 then
            memoDeleteChar(el, repeatKey)
          end
        end, 80, 0, memoEl)
      end
      triggerEvent("onClientUICaretPositionChange", UI.FocusElement, uiMemoGetCaretIndex(UI.FocusElement))
    elseif repeatTimer and isTimer(repeatTimer) then
      killTimer(repeatTimer)
    end
  end
end
bindKey("backspace", "both", handleTextKey)
bindKey("delete", "both", handleTextKey)
function acceptedEvent(arg0, arg1)
  if UI.FocusElement and getElementType(UI.FocusElement) == "ui-edit" and not UI.DB[UI.FocusElement].data.readonly and arg1 == "up" then
    triggerEvent("onClientUIAccepted", UI.FocusElement)
  end
end
bindKey("enter", "both", handleTextKey)
bindKey("num_enter", "both", handleTextKey)
addEventHandler("onClientUIPropertyChange", resourceRoot, function(arg0, arg1)
  if isUIElement(source, "combobox") then
    if arg0 == "items_per_page" then
      uiScrollBarSetScrollPosition(UI.DB[source].scrollbar.element, 0)
      UI.DB[source].data.shown_items = {
        1,
        math.min(uiComboBoxGetItemsCount(source), arg1)
      }
      UI.DB[UI.DB[source].scrollbar.element].visible = arg1 < uiComboBoxGetItemsCount(source) and UI.DB[source].data.visible or false
    elseif arg0 == "Disabled" then
      UI.DB[source].data.visible = UI.DB[source].data.visible and arg1 ~= "True"
    end
  elseif isUIElement(source, "tab") then
    if arg0 == "Disabled" and arg1 == "True" and isUIElement(getElementParent(source), "tabpanel") and source == UI.DB[getElementParent(source)].data.selected_tab then
      uiSetSelectedTab(getElementParent(source))
    end
  elseif isUIElement(source, "tabpanel") then
    if arg0 == "Disabled" and arg1 == "True" then
      uiSetSelectedTab(source)
    end
  elseif isUIElement(source, "label") and arg0 == "scrollbar" then
    updateLabelScroll(source)
  end
end)
addEventHandler("onClientUIBlur", resourceRoot, function()
  if getElementType(source) == "ui-edit" or getElementType(source) == "ui-memo" then
    toggleControl("chatbox", true)
  end
end)
function cancelBindsOnTyping(arg0, arg1)
  -- [Fix #53 - user] This used to cancelEvent() for backspace/delete/enter/
  -- arrows while an edit was focused. Since MTA 1.4 cancelling onClientKey
  -- suppresses ALL binds bound to that key ("all GTA and MTA binds, bound to
  -- the canceled key, won't be triggered") — which silenced UIKit's OWN
  -- bindKey handlers: removeText (backspace/delete), moveCaret (arrows) and
  -- acceptedEvent (enter). onClientCharacter is a separate event, so typing
  -- kept working while deleting never did: exactly the user's report
  -- ("can type but cannot delete a wrong character" in login, staff rank
  -- name, TAB search). Only key PRESSED is cancellable anyway (release is
  -- not), so the old guard could never behave symmetrically. Cancelling is
  -- intentionally disabled; the cancelKeys table is kept for reference.
  return
end
addEventHandler("onClientKey", root, cancelBindsOnTyping)
-- [Fix #76/#83 - user] onClientKey fires in EVERY input mode (binds do not:
-- guiSetInputEnabled(true) kills them — the login screen proves it). Text
-- keys are routed through the shared handleTextKey above; every other key
-- is canceled while a UIKit input has focus so game binds/controls stay
-- quiet until the user clicks outside the text rect.
-- Old bugs fixed here: isChatBoxOpen() does not exist in this MTA build
-- (the handler crashed with "attempt to call global 'isChatBoxOpen'" on
-- every key press, so NOTHING was ever dispatched), and onClientKey hands
-- a boolean press flag while removeText/moveCaret expect "down"/"up".
addEventHandler("onClientKey", root, function(key, press)
  if TEXT_KEYS[key] then
    handleTextKey(key, press and "down" or "up")
  end
  if press and isTypingFocus() and not (isChatBoxInputActive and isChatBoxInputActive()) and not allowWhileTyping(key) then
    cancelEvent()
  end
end)
addEventHandler("onClientUITextChange", resourceRoot, function()
  if isUIElement(source, "label") then
  end
end)
function moveElement(arg0, arg1, arg2, arg3)
  if not isUIElement(UI.FocusElement, "window", "dialog") then
    removeEventHandler("onClientCursorMove", root, moveElement)
    return
  end
  local mcx, mcy, mox, moy = unpack(moveTemp)
  uiSetPosition(UI.FocusElement, arg2 - mcx + mox, arg3 - mcy + moy)
end
function dragElement(arg0, arg1, arg2, arg3)
  local dcx, dcy, dox, doy = unpack(dragTemp)
  UI.DB[UI.DraggedElement].dimensions.x = arg2 - dcx + dox
  UI.DB[UI.DraggedElement].dimensions.y = arg3 - dcy + doy
end
