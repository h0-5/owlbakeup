-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

sx, sy = guiGetScreenSize()
ref_sx, ref_sy = 1728, 972
if sx == 800 and sy == 600 then
  ref_sx, ref_sy = 1024, 768
end
SCALE_X, SCALE_Y = sx / ref_sx, sy / ref_sy
if sx == 800 and sy == 600 then
  SCALE_X, SCALE_Y = SCALE_X * 0.7, SCALE_Y * 0.85
  ref_sx, ref_sy = sx / SCALE_X, sy / SCALE_Y
end
if sx == 1024 and sy == 768 then
  SCALE_X, SCALE_Y = SCALE_X * 1.05, SCALE_Y * 0.9
  ref_sx, ref_sy = sx / SCALE_X, sy / SCALE_Y
end
function uiGetReferenceScreenSize()
  return ref_sx, ref_sy
end
UI = {
  postGUI = true,
  subPixelPositioning = true,
  DB = {},
  Elements = {},
  DrawElements = {},
  HoveredElement = false,
  FocusElement = false,
  VisibleList = false,
  isDraw = {},
  getDrawFunction = {},
  ResourceElements = {},
  TempDisabled = {},
  priority = {},
  SelectedRadio = {},
  TempHoveredElement = false,
  isInDrawingList = {},
  renderStatus = true,
  scaleXFactor = sx / 1024,
  scaleYFactor = sy / 768
}
newLinePrefix = "@@@@@@@@@@@@@@@NEWS_LINE@@@@@@@@@@@@@@@@"
-- [Fix #82 - memo] the decompiled memo code assigned into a FRESH table
-- returned by split(...) and then concatenated the UNCHANGED original text,
-- so every memo edit (type / backspace / delete / enter / paste) silently
-- discarded the change: the report window could not accept a single letter.
-- One shared pair of helpers keeps the "prefix each split line" convention
-- the rest of the memo code expects.
function memoSplitLines(text)
  local raw = tostring(text or ""):gsub("\n", "\n" .. newLinePrefix)
  if raw:find("\n", 1, true) then
    return split(raw, 10)
  end
  return { raw }
end
function memoJoinLines(lines)
  return (table.concat(lines, "\n"):gsub(newLinePrefix, ""))
end
function memoSetText(el, newText)
  local db = UI.DB[el]
  uiSetText(el, newText)
  -- the old code also refreshed the visible window from line_i after an edit
  local lines = memoSplitLines(db.text)
  local fontH = dxGetFontHeight(db.font.size, db.font.name)
  local first = math.max(1, math.min(tonumber(db.data.line_i) or 1, #lines))
  local last = math.min(#lines, first + math.floor(db.dimensions.height / fontH) + 1)
  db.data.showtext = (table.concat(lines, "\n", first, last):gsub(newLinePrefix, ""))
end
function memoDeleteChar(el, key)
  local db = UI.DB[el]
  if not db or not db.data or not db.text then return end
  local lines = memoSplitLines(db.text)
  if #lines == 0 then return end
  local li = math.max(1, math.min(db.data.caretLine or 1, #lines))
  local line = (lines[li] or ""):gsub(newLinePrefix, "")
  if key == "backspace" then
    if db.data.caret == 1 then
      if li == 1 then return end
      local prev = (lines[li - 1] or ""):gsub(newLinePrefix, "")
      db.data.caret = utfLen(prev) + 1
      lines[li - 1] = prev .. line
      table.remove(lines, li)
      db.data.caretLine = li - 1
    elseif db.data.caret > 1 then
      lines[li] = utfSub(line, 1, db.data.caret - 2) .. utfSub(line, db.data.caret, utfLen(line))
      db.data.caret = db.data.caret - 1
    else
      return
    end
  else
    if db.data.caret > utfLen(line) then
      if li >= #lines then return end
      lines[li] = line .. ((lines[li + 1] or ""):gsub(newLinePrefix, ""))
      table.remove(lines, li + 1)
    else
      lines[li] = utfSub(line, 1, db.data.caret - 1) .. utfSub(line, db.data.caret + 1, utfLen(line))
    end
  end
  memoSetText(el, memoJoinLines(lines))
end
dxFont = dxCreateFont("fonts/Font2.ttf", 11.5 * SCALE_Y)
dxFontLarge = dxCreateFont("fonts/Font2.ttf", 15 * SCALE_Y)
dxFontHUD = dxCreateFont("fonts/PFDinDisplayPro-Regular.ttf", 15 * SCALE_Y, false) or "default"
dxFontHUDLarge = dxCreateFont("fonts/PFDinDisplayPro-Bold.ttf", 35 * SCALE_Y) or "default"
function restartUIKit()
  removeEventHandler("onClientElementDestroy", resourceRoot, UI.onElementDestroy)
  for forvar3, forvar4 in ipairs(UI.Elements) do
    if isElement(forvar4) then
      destroyElement(forvar4)
    end
  end
  UI.priority = {}
  UI.isInDrawingList = {}
  UI.Elements = {}
  UI.DrawElements = {}
  UI.DB = {}
  UI.isDraw = {}
  UI.ResourceElements = {}
  UI.TempDisabled = {}
  UI.SelectedRadio = {}
  UI.HoveredElement = false
  UI.FocusElement = false
  UI.VisibleList = false
  UI.TempHoveredElement = false
  triggerEvent("onClientUIKitReady", root)
  addEventHandler("onClientElementDestroy", resourceRoot, UI.onElementDestroy)
end
if not dxFont then
  dxFont = "default"
end
if not dxFontLarge then
  dxFontLarge = "default"
end
UIFonts = {
  ["ui-default"] = dxFont,
  ["default-large"] = dxFontLarge,
  ["hud"] = dxFontHUD,
  ["hud-large"] = dxFontHUDLarge
}
language = "ar"
function updateTexturesSettings()
  if exports.settings:getSetting("language") then
    language = "ar"
  else
    language = "en"
  end
end
addEvent("onClientSettingsReady", true)
addEventHandler("onClientSettingsReady", resourceRoot, updateTexturesSettings)
addEvent("onClientSettingChange", false)
addEventHandler("onClientSettingChange", localPlayer, function(arg0, arg1, arg2)
  if arg0 == "language" then
    if arg2 then
      language = "ar"
    else
      language = "en"
    end
  end
end)
floor = math.floor
-- [Vortex fix #10] the decompiler dropped the original global text helpers
-- (it only kept 'floor = math.floor'). They are used 155x across
-- c_edit/c_memo/c_process INCLUDING the ui-edit and ui-memo draw handlers;
-- as undefined globals they raised 'attempt to call nil' EVERY frame a
-- visible edit/memo drew, and UI.drawing() has no pcall, so everything
-- below the first visible edit/memo never rendered (empty changelogs/
-- add-staff/ranks sections). Restored, UTF-8 aware with safe fallbacks.
utfLen = utfLen or function(s)
    s = tostring(s or "")
    local ok, n = pcall(utf8.len, s)
    if ok and n then return n end
    return #s
end
utfSub = utfSub or function(s, i, j)
    local ok, r = pcall(utf8.sub, tostring(s or ""), i, j)
    if ok and r then return r end
    return string.sub(tostring(s or ""), i, j)
end
tocolor = tocolor
addEvent("onClientUIClick", false)
addEvent("onClientUIStartClick", false)
addEvent("onClientUIScroll", false)
addEvent("onClientUIDoubleClick", false)
addEvent("onClientUIBlur", false)
addEvent("onClientUIFocus", false)
addEvent("onClientUIMouseEnter", false)
addEvent("onClientUIMouseLeave", false)
addEvent("onClientUIGridlistItemSelected", false)
addEvent("onClientUIComboBoxAccepted", false)
addEvent("onClientUITextChange", false)
addEvent("onClientUIChanged", false)
addEvent("onClientUIPropertyChange", false)
addEvent("onClientUIAccepted", false)
addEvent("onClientUITabSwitched", false)
addEvent("onClientUIProgressBarChange", false)
addEvent("onClientUICaretPositionChange", false)
addEvent("onClientUIVisibilityChange", false)
addEvent("onClientUIParentChange", false)
addEvent("onClientUIReady", false)
addEvent("onClientUIKitReady", false)
addEvent("onClientUIMenuSelectChange", false)
addEvent("onClientUIDialogButtonClick", false)
addEvent("onClientUIDragStart", false)
addEvent("onClientUIDragEnd", false)
function addUIElement(arg0, arg1, arg2)
  UI.DB[arg0].related_dimensions_org = {
    x = UI.DB[arg0].related_dimensions.x,
    y = UI.DB[arg0].related_dimensions.y,
    width = UI.DB[arg0].related_dimensions.width,
    height = UI.DB[arg0].related_dimensions.height
  }
  if arg1 then
    UI.DB[arg0].related_dimensions.x, UI.DB[arg0].related_dimensions.y, UI.DB[arg0].related_dimensions.width, UI.DB[arg0].related_dimensions.height = UI.DB[arg0].related_dimensions.x * SCALE_Y, UI.DB[arg0].related_dimensions.y * SCALE_Y, UI.DB[arg0].related_dimensions.width * SCALE_Y, UI.DB[arg0].related_dimensions.height * SCALE_Y
    if UI.DB[arg1].padding then
      UI.DB[arg0].related_dimensions.x, UI.DB[arg0].related_dimensions.y = UI.DB[arg0].related_dimensions.x + UI.DB[arg1].padding.left * SCALE_Y, UI.DB[arg0].related_dimensions.y + UI.DB[arg1].padding.top * SCALE_Y
    end
  else
    UI.DB[arg0].related_dimensions.x, UI.DB[arg0].related_dimensions.y, UI.DB[arg0].related_dimensions.width, UI.DB[arg0].related_dimensions.height = UI.DB[arg0].related_dimensions.x * SCALE_X + (UI.DB[arg0].related_dimensions.width * SCALE_X - UI.DB[arg0].related_dimensions.width * SCALE_Y) / 2, UI.DB[arg0].related_dimensions.y * SCALE_Y, UI.DB[arg0].related_dimensions.width * SCALE_Y, UI.DB[arg0].related_dimensions.height * SCALE_Y
  end
  UI.DB[arg0].related_dimensions = UI.DB[arg0].related_dimensions
  table.insert(UI.Elements, arg0)
  UI.isInDrawingList[arg0] = true
  UI.priority[arg0] = #UI.Elements
  UI.DB[arg0].priority = #UI.Elements
  UI.DB[arg0].state = "normal"
  addToResourceElements(arg0, arg2)
  uiSetParent(arg0, arg1)
  UI.updateDrawingList()
  if not UI.renderStatus then
    addEventHandler("onClientRender", root, UI.drawing)
    UI.renderStatus = true
  end
end
function addToResourceElements(arg0, arg1)
  if arg1 then
    UI.ResourceElements[arg1] = UI.ResourceElements[arg1] or {}
    table.insert(UI.ResourceElements[arg1], arg0)
  end
end
addEventHandler("onClientResourceStop", root, function(arg0)
  if UI.ResourceElements[arg0] then
    for forvar4, forvar5 in ipairs(UI.ResourceElements[arg0]) do
      if isElement(forvar5) then
        destroyElement(forvar5)
      end
    end
    -- [Fix #32 - F1 DEAD] the decompiled rebuild here was destroyed
    -- (table.insert({}, ...) into a discarded table) and then
    -- UI.Elements was wiped to {}: stopping ANY resource that owns
    -- UIKit elements (the scoreboard owns its search edit since
    -- Fix #31) dropped EVERY other resource's windows from the
    -- drawing list FOREVER - the F1 menu stopped opening right after
    -- the last deploy restarts. Keep every element that survived.
    local kept = {}
    for i = 1, #UI.Elements do
      local el = UI.Elements[i]
      if isElement(el) then
        kept[#kept + 1] = el
      end
    end
    UI.Elements = kept
    UI.updateDrawingList()
  end
  if arg0 then
    UI.ResourceElements[arg0] = nil
  end
end)
addEventHandler("onClientResourceStart", root, function(arg0)
  triggerEvent("onClientUIReady", getResourceRootElement(arg0))
end)
addEventHandler("onClientResourceStart", resourceRoot, function()
  triggerEvent("onClientUIKitReady", root)
end)
function UI.onElementDestroy()
  -- [Fix #52] the decompiled body indexed UI.DB[source].scrollbar twice: once
  -- when .scrollbar was missing (old line 222) and again AFTER
  -- UI.DB[source] had already been set to nil (old line 249) -- a guaranteed
  -- error on every element destroy. Snapshot the record, guard every field,
  -- and let the children loop below clean up child scrollbars.
  local db = UI.DB[source]
  if db and isUIElement(source, "combobox", "memo", "gridlist") then
    local sb = db.scrollbar
    if sb and type(sb.element) ~= "table" and isElement(sb.element) then
      destroyElement(sb.element)
    end
  elseif db and isUIElement(source, "browser") and db.data and isElement(db.data.browser) then
    destroyElement(db.data.browser)
  end
  UI.priority[source] = nil
  UI.DB[source] = nil
  if UI.FocusElement == source then
    triggerEvent("onClientUIBlur", UI.FocusElement)
    UI.FocusElement = false
  end
  if UI.HoveredElement == source then
    UI.HoveredElement = false
  end
  if UI.DraggedElement == source then
    UI.DraggedElement = false
  end
  if UI.VisibleList == source then
    UI.VisibleList = false
  end
  if UI.SelectedRadio == source then
    UI.SelectedRadio = false
  end
  for forvar4, forvar5 in ipairs(getElementChildren(source)) do
    destroyElement(forvar5)
  end
  for forvar4, forvar5 in ipairs(UI.Elements) do
    if forvar5 == source then
      table.remove(UI.Elements, forvar4)
      break
    end
  end
  if UI.isDraw[source] then
    UI.updateDrawingList()
  end
  UI.isDraw[source] = nil
end

addEventHandler("onClientElementDestroy", resourceRoot, UI.onElementDestroy)
-- [Vortex fix] an element may only draw if it AND every ancestor above it are
-- visible. Without this chain check, hiding the top-level window left its
-- whole subtree on screen (panel visible before login, sections stacked).
function UI.isHierarchyVisible(el)
  local parent = getElementParent(el)
  while parent and isElement(parent) and isUIElement(parent) do
    if not UI.DB[parent] or not UI.DB[parent].visible then
      return false
    end
    parent = getElementParent(parent)
  end
  return true
end
function uiSetVisible(arg0, arg1)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetVisible' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].visible = type(arg1) == "boolean" and arg1 or false
  UI.updateDrawingList()
  triggerEvent("onClientUIVisibilityChange", arg0, type(arg1) == "boolean" and arg1 or false)
  if arg1 and not UI.renderStatus then
    addEventHandler("onClientRender", root, UI.drawing)
    UI.renderStatus = true
  end
  -- [Vortex fix] hidden elements must not keep focus or hover invisibly
  if not UI.DB[arg0].visible then
    local stillDrawn = {}
    for forvar4 = 1, #UI.DrawElements do
      stillDrawn[UI.DrawElements[forvar4]] = true
    end
    local focused = UI.FocusElement
    if focused and isElement(focused) and not stillDrawn[focused] then
      UI.FocusElement = false
      UI.DB[focused].state = "normal"
      triggerEvent("onClientUIBlur", focused)
    end
    if UI.TempHoveredElement and isElement(UI.TempHoveredElement) and not stillDrawn[UI.TempHoveredElement] then
      UI.TempHoveredElement = false
      UI.HoveredElement = false
    end
  end
  return true
end
function addToDrawElements(arg0)
  UI.isInDrawingList[arg0] = true
  for forvar4, forvar5 in ipairs(getElementChildren(arg0)) do
    addToDrawElements(forvar5)
  end
end
function removeFromDrawElements(arg0)
  UI.isInDrawingList[arg0] = nil
  for forvar4, forvar5 in ipairs(getElementChildren(arg0)) do
    removeFromDrawElements(forvar5)
  end
end
function uiGetVisible(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetVisible' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].visible
end
function uiGetText(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetText' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  -- [Vortex fix #13] the decompiler emptied the bilingual branch: every
  -- label stores {en=,ar=} and the old body returned tostring(table) --
  -- the delete-staff dialog then sent "table: 0x..." as the username!
  local t = UI.DB[arg0].text
  if type(t) == "table" then
    local pick = language and t[language] or nil
    if pick then return tostring(pick) end
    return tostring(t.en or t.ar or "")
  end
  return tostring(t or "")
end
function uiSetText(arg0, arg1)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetText' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if type(UI.DB[arg0].text) == "table" then
    if type(arg1) == "string" then
      arg1 = {en = arg1, ar = arg1}
    end
    arg1.en = formatText(arg1.en)
    arg1.ar = formatText(arg1.ar)
  end
  UI.DB[arg0].text = arg1
  if getElementType(arg0) == "ui-memo" then
    adjustMemoText(uiScrollBarGetScrollPosition(UI.DB[arg0].data.scrollbar), arg0)
  end
  triggerEvent("onClientUITextChange", arg0)
  return true
end
function uiGetColor(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetColor' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return dxGetColor(UI.DB[arg0].colors[1])
end
function uiSetColor(arg0, arg1, arg2, arg3, arg4)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetColor' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].colors[1] = tocolor(arg1 or 255, arg2 or 255, arg3 or 255, arg4 or 255)
  return true
end
function uiSetAlpha(arg0, arg1)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetAlpha' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "number", "Bad argument @ 'uiSetAlpha' [Expected number at argument 2, got " .. type(arg1) .. "]")
  UI.DB[arg0].colors[1] = tocolor(dxGetColor(UI.DB[arg0].colors[1]))
  return true
end
function uiGetAlpha(arg0, arg1)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetAlpha' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return dxGetColor(UI.DB[arg0].colors[1])
end
function uiGetFont(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetFont' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].font.name
end
function uiGetFontSize(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetFontSize' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].font.size
end
function uiSetFont(arg0, arg1)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetFont' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].font.name = type(arg1) == "string" and UIFonts[arg1] or arg1 or dxFont
  return true
end
function uiSetFontSize(arg0, arg1)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetFontSize' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].font.size = arg1 or 1
  return true
end
function getUIFont(arg0)
  return type(arg0) == "string" and UIFonts[arg0] or arg0 or dxFont
end
function uiSetAlignX(arg0, arg1)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetAlignX' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].align.X = arg1 or UI.DB[arg0].align.X
  return true
end
function uiSetAlignY(arg0, arg1)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetAlignY' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].align.Y = arg1 or UI.DB[arg0].align.Y
  return true
end
function uiSetAlign(arg0, arg1, arg2)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetAlign' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].align.X = arg1 or UI.DB[arg0].align.X
  UI.DB[arg0].align.Y = arg2 or UI.DB[arg0].align.Y
  return true
end
function uiSetProperty(arg0, arg1, arg2)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetProperty' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].properties[arg1], "Bad argument @ 'uiSetProperty' [There's no such property]")
  assert(type(arg2) == UI.DB[arg0].properties[arg1].valueType, "Bad argument @ 'uiSetProperty' [Expected " .. UI.DB[arg0].properties[arg1].valueType .. " at argument 3, got " .. type(arg2) .. "]")
  assert(type(UI.DB[arg0].properties[arg1].acceptedValues) ~= "table" or not not table.find(UI.DB[arg0].properties[arg1].acceptedValues, arg2), "Bad argument @ 'uiSetProperty' Passed value is not accepted")
  UI.DB[arg0].properties[arg1].value = arg2
  triggerEvent("onClientUIPropertyChange", arg0, arg1, arg2)
  return true
end
function uiGetProperty(arg0, arg1)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetProperty' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(UI.DB[arg0].properties[tostring(arg1)], "Bad argument @ 'uiGetProperty' [There's no such property]")
  return UI.DB[arg0].properties[tostring(arg1)].value
end
function uiGetProperties(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetProperties' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  local result = {}
  for forvar5, forvar6 in pairs(UI.DB[arg0].properties) do
    result[forvar5] = forvar6.value
  end
  return result
end
function uiSetPosition(arg0, arg1, arg2)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetPosition' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].related_dimensions.x = arg1
  UI.DB[arg0].related_dimensions.y = arg2
  if isUIElement(getElementParent(arg0)) then
    arg1 = arg1 + UI.DB[arg0].dimensions.x
    arg2 = arg2 + UI.DB[arg0].dimensions.y
  end
  uiSetPos(arg0, arg1, arg2)
  return true
end
function uiSetPos(arg0, arg1, arg2)
  UI.DB[arg0].dimensions.x = arg1
  UI.DB[arg0].dimensions.y = arg2
  if getElementType(arg0) == "ui-scrollbar" then
    uiScrollBarSetScrollPosition(arg0, getElementType(arg0) == "ui-scrollbar" and uiScrollBarGetScrollPosition(arg0) or 0)
  end
  for forvar8, forvar9 in ipairs(getElementChildren(arg0)) do
    uiSetPos(forvar9, arg1 + UI.DB[forvar9].related_dimensions.x, arg2 + UI.DB[forvar9].related_dimensions.y)
  end
  return true
end
function uiGetPosition(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetPosition' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].related_dimensions.x, UI.DB[arg0].related_dimensions.y
end
-- [Fix #32] ABSOLUTE on-screen rect (what the draw loop actually paints).
-- external hit-tests (staff panel / color picker) must use this instead of
-- re-deriving UIKit geometry by hand - the hand-rolled math drifted and
-- clicks landed one palette row below the swatch.
function uiGetAbsoluteBounds(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetAbsoluteBounds' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  local d = UI.DB[arg0].dimensions
  return d.x, d.y, d.width, d.height
end
function uiSetSize(arg0, arg1, arg2)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetSize' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].related_dimensions_org.width = arg1
  UI.DB[arg0].related_dimensions_org.height = arg2
  UI.DB[arg0].related_dimensions.width = arg1 * SCALE_Y
  UI.DB[arg0].related_dimensions.height = arg2 * SCALE_Y
  UI.DB[arg0].dimensions.width = arg1 * SCALE_Y
  UI.DB[arg0].dimensions.height = arg2 * SCALE_Y
  return true
end
function uiGetSize(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetSize' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].related_dimensions_org.width, UI.DB[arg0].related_dimensions_org.height
end
local frontList = {}
function uiBringToFront(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiBringToFront' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  while isUIElement(getElementParent(arg0)) do
    arg0 = getElementParent(arg0)
  end
  for forvar4, forvar5 in ipairs(frontList) do
    if isElement(forvar5) then
      UI.priority[forvar5] = UI.DB[forvar5].priority
    end
  end
  frontList = {}
  bringToFront(arg0, #UI.Elements + 10000)
  table.sort(UI.Elements, function(arg0, arg1)
    return (UI.priority[arg0] or 0) < (UI.priority[arg1] or 0)
  end)
  UI.updateDrawingList()
end
function bringToFront(arg0, arg1)
  UI.priority[arg0] = arg1
  table.insert(frontList, arg0)
  for forvar5, forvar6 in ipairs(getElementChildren(arg0)) do
    if isUIElement(forvar6) then
      bringToFront(forvar6, arg1 + 1)
    end
  end
end
function uiSetParent(arg0, arg1)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetParent' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if not UI.DB[arg0].dimensions then
    UI.DB[arg0].dimensions = {}
    for forvar5, forvar6 in pairs(UI.DB[arg0].related_dimensions) do
      UI.DB[arg0].dimensions[forvar5] = forvar6
    end
  end
  if isUIElement(arg1) and arg0 ~= arg1 then
    if getElementType(arg0) ~= "ui-tab" and getElementType(arg1) == "ui-tabpanel" then
      uiSetPos(arg0, UI.DB[arg0].dimensions.x + UI.DB[uiCreateTab(UI.DB[arg0].text, UI.DB[arg0].text, arg1)].dimensions.x, UI.DB[arg0].dimensions.y + UI.DB[uiCreateTab(UI.DB[arg0].text, UI.DB[arg0].text, arg1)].dimensions.y)
      setElementParent(arg0, (uiCreateTab(UI.DB[arg0].text, UI.DB[arg0].text, arg1)))
      triggerEvent("onClientUIParentChange", arg0, getElementType(getElementParent(arg0)) ~= "map" and getElementParent(arg0) or nil, (uiCreateTab(UI.DB[arg0].text, UI.DB[arg0].text, arg1)))
      return true
    end
    uiSetPos(arg0, UI.DB[arg0].related_dimensions.x + UI.DB[arg1].dimensions.x, UI.DB[arg0].related_dimensions.y + UI.DB[arg1].dimensions.y)
    setElementParent(arg0, arg1)
    triggerEvent("onClientUIParentChange", arg0, getElementType(getElementParent(arg0)) ~= "map" and getElementParent(arg0) or nil, arg1)
    return true
  elseif getElementType(getElementParent(arg0)) ~= "map" then
    uiSetPos(arg0, UI.DB[arg0].related_dimensions.x, UI.DB[arg0].related_dimensions.y)
    setElementParent(arg0, getResourceDynamicElementRoot(getThisResource()))
    triggerEvent("onClientUIParentChange", arg0, getElementType(getElementParent(arg0)) ~= "map" and getElementParent(arg0) or nil)
    return true
  end
  return false
end
function uiGetParent(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiGetParent' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return getElementType(getElementParent(arg0)) ~= "map" and getElementParent(arg0) or nil
end
function uiSetClickAction(arg0, arg1, arg2)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetClickAction' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or arg1(arg0)) .. "]")
  if arg1 and arg2 == nil and type(arg1) == "string" then
    -- bare link/text: treat as a copy-to-clipboard action (original client usage)
    arg1, arg2 = "copy_text", arg1
  end
  if arg1 then
    UI.DB[arg0].click_action = {type = arg1, value = arg2}
  else
    UI.DB[arg0].action = nil
  end
  return true
end
addEventHandler("onClientUIClick", resourceRoot, function()
  if UI.DB[source] then
    if not UI.DB[source].click_action then
      return
    end
    if UI.DB[source].click_action.type == "show_ui" then
      uiSetVisible(UI.DB[source].click_action.value, true)
    elseif UI.DB[source].click_action.type == "hide_ui" then
      uiSetVisible(UI.DB[source].click_action.value, false)
    elseif UI.DB[source].click_action.type == "copy_text" then
      setClipboard(UI.DB[source].click_action.value)
    end
  end
end)
function uiDragElement(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiDragElement' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if UI.DraggedElement then
    return
  end
  UI.DraggedElement = arg0
  -- [Vortex fix] capture both cursor coords (decompiler lost the y local)
  local dcx, dcy = getCursorPosition()
  dragTemp = {
    (dcx or 0) * sx,
    (dcy or 0) * sy,
    UI.DB[arg0].dimensions.x,
    UI.DB[arg0].dimensions.y
  }
  addEventHandler("onClientCursorMove", root, dragElement)
  triggerEvent("onClientUIDragStart", arg0)
  return true
end
function uiCenterElement(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiCenterElement' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  uiSetPosition(arg0, (sx - uiGetSize(arg0)) / 2, (sy - uiGetSize(arg0)) / 2)
  return true
end

-- [Vortex fix #13] cross-resource keyboard focus: lets a host panel place
-- focus on a ui-edit even when UIKit's own click pipeline is not alive
-- (the raw-input fallback in staff_manager calls this on edit clicks).
-- [Fix #35 - user] "في تاب البحث عبارة عن منظر لاتقدر تكتب ولا تحذف" (+ same
-- for the checkid search): this helper set UI.FocusElement but never did
-- what UIKit's own click path does (c_process 293/313/389/429) —
-- toggleControl("chatbox", false). With the chat input still armed every
-- typed key opened the MTA chat box and the edit never received a single
-- character (and nothing could be deleted either). Disable it on edit focus;
-- the onClientUIBlur handler re-arms it when focus leaves.
function uiSetFocusedElement(arg0)
  assert(isUIElement(arg0), "Bad argument @ 'uiSetFocusedElement' [Expected ui-element at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  if UI.FocusElement and isElement(UI.FocusElement) and UI.FocusElement ~= arg0 then
    UI.DB[UI.FocusElement].state = "normal"
    triggerEvent("onClientUIBlur", UI.FocusElement)
  end
  UI.FocusElement = arg0
  UI.DB[arg0].state = "normal"
  triggerEvent("onClientUIFocus", arg0)
  if getElementType(arg0) == "ui-edit" or getElementType(arg0) == "ui-memo" then
    toggleControl("chatbox", false)
  end
  return true
end
