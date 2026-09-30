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
-- [Fix #151] drawing only. The old body ALSO drove the drag, but it read the
-- cursor while state == "clicked" - a state UI.drawing resets EVERY frame for
-- non-button elements (c_process) - and even then gated the notification on
-- `data.scroll ~= data.scroll`, which is always false: dragging moved nothing
-- and a track press teleported the thumb while the content stayed behind.
-- The drag now lives in uiScrollBarDragMove below; this keeps the look:
-- slim dark track + slightly lighter rounded thumb on the right edge.
UI.getDrawFunction["ui-scrollbar"] = function(arg0)
  local db = UI.DB[arg0]
  local d = db.dimensions
  -- [Fix #151] release safety net: onClientClick(left, up) ends the drag, but
  -- if that was ever swallowed (cursor hidden mid-drag) the draw tick ends it
  -- the moment the button is up, so no half-finished drag can be left behind.
  if UI.ScrollbarDrag and UI.ScrollbarDrag.element == arg0 and not getKeyState("mouse1") then
    uiScrollBarDragStop()
  end
  hoverUIElement(arg0, d.x, d.y, d.width, d.height)
  -- [Fix #151] visible track: gridlist/memo/menu/checklist create the strip
  -- with a fully transparent track color, so only the thumb was ever painted
  -- and the lane itself was invisible. Fall back to a dark strip (target
  -- look: slim dark track, lighter thumb, right edge of the panel) and keep
  -- the caller's own color whenever it has alpha (combobox dark track).
  local tr, tg, tb, ta = dxGetColor(db.colors[2])
  if ta == 0 then
    tr, tg, tb, ta = 0, 0, 0, 90
  end
  local trackColor = tocolor(tr, tg, tb, ta)
  dxDrawRectangle(d.x, d.y, d.width, d.height, trackColor, UI.postGUI)
  dxDrawEmptyLine(d.x - 1, d.y - 1, d.width, d.height, trackColor, 2, UI.postGUI)
  local r, g, b, a = dxGetColor(db.colors[1])
  local dragging = UI.ScrollbarDrag and UI.ScrollbarDrag.element == arg0 or false
  if a < 160 and (dragging or UI.HoveredElement == arg0) then
    -- [Fix #151] slightly lighter thumb while hovered / grabbed
    a = 160
  end
  local thumbColor = tocolor(r, g, b, a)
  local thumb = db.properties.thumb_size.value
  if db.data.horizontal then
    dxDrawRoundedRectangle(db.data.scrollX, d.y + 1, thumb, d.height - 2, thumbColor, math.min(2, thumb / 2, (d.height - 2) / 2))
  else
    dxDrawRoundedRectangle(d.x + 1, db.data.scrollY, d.width - 2, thumb, thumbColor, math.min(2, (d.width - 2) / 2, thumb / 2))
  end
end
-- [Fix #151] thumb / track drag ------------------------------------------------
-- UIKit scrollbars are custom drawn (no guiScrollBar), so the wheel path
-- (MouseWheel, untouched below) was the only way to scroll. This makes the
-- strip grabbable everywhere at once - gridlist, memo, menu, checklist,
-- combobox dropdown and every standalone uiCreateScrollBar - because they all
-- share this one component and all of them already listen for onClientUIScroll.
--
-- Wiring:
--   press   -> onClientUIStartClick, fired by UI.click with source = the
--              element UIKit resolved under the cursor. A scrollbar press can
--              not reach the ui-window/ui-dialog move branch or uiDragElement
--              (both are keyed on the HOVERED element being that element), so
--              grabbing the thumb never starts moving the window.
--   move    -> onClientCursorMove while mouse1 is held; the thumb maps to
--              0..100 and is pushed through the same onClientUIScroll event
--              the mouse wheel uses (no consumer changes needed).
--   release -> onClientClick(left, up): fires wherever the cursor is, which
--              onClientUIClick does not (it needs the same element hovered).
local function uiScrollBarTravel(db)
  local d = db.dimensions
  local thumb = db.properties.thumb_size.value
  if db.data.horizontal then
    return d.width - 2 - thumb, d.x + 1, d.x + d.width - 1 - thumb
  end
  return d.height - 2 - thumb, d.y + 1, d.y + d.height - 1 - thumb
end
local function uiScrollBarApplyDrag(el, db, thumbPos)
  local travel, minPos, maxPos = uiScrollBarTravel(db)
  if not travel or travel <= 0 then
    return
  end
  local pos = thumbPos
  if pos < minPos then
    pos = minPos
  elseif pos > maxPos then
    pos = maxPos
  end
  local percent = (pos - minPos) / travel * 100
  if percent < 0 then
    percent = 0
  elseif percent > 100 then
    percent = 100
  end
  -- thumb stays pixel exact under the cursor ...
  if db.data.horizontal then
    db.data.scrollX = pos
  else
    db.data.scrollY = pos
  end
  -- ... consumers get the rounded percent, exactly like uiScrollBarSetScrollPosition
  local rounded = floor(percent + 0.5)
  if rounded ~= db.data.scroll then
    db.data.scroll = rounded
    triggerEvent("onClientUIScroll", el, rounded)
  end
end
function uiScrollBarDragStop()
  UI.ScrollbarDrag = false
  if isEventHandlerAdded("onClientCursorMove", root, uiScrollBarDragMove) then
    removeEventHandler("onClientCursorMove", root, uiScrollBarDragMove)
  end
end
function uiScrollBarDragMove()
  local drag = UI.ScrollbarDrag
  if not drag then
    -- [Fix #151] stale handler (element destroyed / UIKit restarted): drop it
    uiScrollBarDragStop()
    return
  end
  local el = drag.element
  local db = isElement(el) and UI.DB[el]
  if not db or not isUIElement(el, "scrollbar") or not db.visible or isUIDisabled(el) then
    uiScrollBarDragStop()
    return
  end
  if not getKeyState("mouse1") then
    uiScrollBarDragStop()
    return
  end
  local cx, cy = getCursorPosition()
  if not cx then
    return
  end
  local absX, absY = cx * sx, cy * sy
  if db.data.horizontal then
    uiScrollBarApplyDrag(el, db, absX - drag.offset)
  else
    uiScrollBarApplyDrag(el, db, absY - drag.offset)
  end
end
addEventHandler("onClientUIStartClick", resourceRoot, function(absX, absY)
  if not isUIElement(source, "scrollbar") then
    return
  end
  local db = UI.DB[source]
  if not db.visible or isUIDisabled(source) then
    return
  end
  local cx, cy = getCursorPosition()
  if cx then
    absX, absY = cx * sx, cy * sy
  end
  local thumb = db.properties.thumb_size.value
  local offset
  if db.data.horizontal then
    offset = (absX or 0) - db.data.scrollX
  else
    offset = (absY or 0) - db.data.scrollY
  end
  -- inside the thumb: keep the grab point. Outside it: UI.click already
  -- teleported the thumb under the cursor, so this becomes jump + drag.
  if offset < 0 then
    offset = 0
  elseif offset > thumb then
    offset = thumb
  end
  UI.ScrollbarDrag = {element = source, offset = offset}
  if not isEventHandlerAdded("onClientCursorMove", root, uiScrollBarDragMove) then
    addEventHandler("onClientCursorMove", root, uiScrollBarDragMove)
  end
  -- [Fix #151] a track press moved the thumb in UI.click without telling the
  -- consumer: sync it now. A thumb press re-applies the SAME position, so no
  -- event fires and nothing jumps.
  uiScrollBarApplyDrag(source, db, db.data.horizontal and db.data.scrollX or db.data.scrollY)
end)
-- [Fix #151] mouse release ends the drag wherever the cursor let go
addEventHandler("onClientClick", root, function(button, state)
  if button == "left" and state == "up" then
    uiScrollBarDragStop()
  end
end)
function MouseWheel(arg0, arg1)
  if not isUIElement(UI.HoveredElement, "scrollbar") then
    return
  end
  uiScrollBarSetScrollPosition(UI.HoveredElement, (tonumber(UI.DB[UI.HoveredElement].data.scroll) or 0) + (arg0 == "mouse_wheel_up" and -1 or 1) * 5)
end
bindKey("mouse_wheel_up", "both", MouseWheel)
bindKey("mouse_wheel_down", "both", MouseWheel)
