-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateTabPanel(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
  local element = createElement("ui-tabpanel")
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
      arg5 or theme.COLORS.tabpanel_default.background or tocolor(67, 74, 86)
    },
    align = {X = "center", Y = "center"},
    font = {name = dxFont, size = 1},
    data = {
      selected_tab = nil,
      hovered_tab = nil,
      visible_tabs = {}
    },
    animation = {0},
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
      title_shown = {value = false, valueType = "boolean"},
      title_height = {value = 25, valueType = "number"},
      tabs_bar_color = {
        value = theme.COLORS.tabpanel_default.tabs_bar or tocolor(10, 10, 10),
        valueType = "number"
      },
      tab_height = {value = 35, valueType = "number"},
      tab_color = {
        value = tocolor(0, 0, 0, 0),
        valueType = "number"
      },
      tab_selected_color = {
        value = theme.COLORS.tabpanel_default.tab_selected or tocolor(44, 44, 46),
        valueType = "number"
      },
      tab_hovered_color = {
        value = theme.COLORS.tabpanel_default.tab_hovered or tocolor(30, 30, 30),
        valueType = "number"
      },
      tab_disabled_color = {
        value = tocolor(75, 75, 75),
        valueType = "number"
      },
      tab_text_color = {
        value = tocolor(255, 255, 255),
        valueType = "number"
      },
      tab_text_hovered_color = {
        value = tocolor(230, 230, 230),
        valueType = "number"
      },
      tab_text_disabled_color = {
        value = tocolor(255, 255, 255),
        valueType = "number"
      }
    }
  }
  addUIElement(element, arg6, sourceResource)
  return (element)
end
function uiCreateTab(arg0, arg1, arg2)
  local element = createElement("ui-tab")
  if type(arg0) == "string" then
    arg0 = {en = arg0, ar = arg0}
  end
  UI.DB[element] = {
    text = arg0,
    title = arg1 or "",
    colors = {},
    visible = true,
    align = {X = "center", Y = "center"},
    font = {name = dxFont, size = 1},
    related_dimensions = {
      x = 0,
      y = 0,
      width = 0,
      height = 0
    },
    data = {},
    properties = {
      Disabled = {
        value = "False",
        valueType = "string",
        acceptedValues = {"True", "False"}
      }
    }
  }
  addUIElement(element, arg2, sourceResource)
  table.insert(UI.DB[arg2].data.visible_tabs, (element))
  if UI.DB[arg2].data.selected_tab == nil then
    UI.DB[arg2].data.selected_tab = element
  end
  return (element)
end
function uiDeleteTab(arg0)
  assert(isUIElement(arg0, "tab"), "Bad argument @ 'uiDeleteTab' [Expected ui-tab at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return destroyElement(arg0)
end
function uiTabSetTitle(arg0, arg1)
  assert(isUIElement(arg0, "tab"), "Bad argument @ 'uiTabSetTitle' [Expected ui-tab at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(type(arg1) == "string", "Bad argument @ 'uiTabSetTitle' [Expected string at argument 2, got " .. type(arg1) .. "]")
  UI.DB[arg0].title = arg1
  return true
end
function uiTabGetTitle(arg0)
  assert(isUIElement(arg0, "tab"), "Bad argument @ 'uiTabGetTitle' [Expected ui-tab at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].title
end
function uiGetSelectedTab(arg0)
  assert(isUIElement(arg0, "tabpanel"), "Bad argument @ 'uiGetSelectedTab' [Expected ui-tabpanel at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.selected_tab
end
function uiSetSelectedTab(arg0, arg1)
  assert(isUIElement(arg0, "tabpanel"), "Bad argument @ 'uiSetSelectedTab' [Expected ui-tabpanel at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  assert(isUIElement(arg1, "tab") or type(arg1) == "nil", "Bad argument @ 'uiSetSelectedTab' [Expected ui-tab or nil at argument 2, got " .. (isElement(arg1) and getElementType(arg1) or type(arg1)) .. "]")
  if UI.DB[arg0].data.selected_tab ~= arg1 then
    UI.DB[arg0].data.selected_tab = arg1
    -- [Vortex fix] tab children are armed by UI.updateDrawingList; switching
    -- tabs must re-run it or the freshly selected tab stays invisible (and
    -- the old one keeps drawing) until some other visibility change happens.
    UI.updateDrawingList()
    triggerEvent("onClientUITabSwitched", arg0, UI.DB[arg0].data.selected_tab, arg1)
    return true
  end
  return false
end
UI.getDrawFunction["ui-tabpanel"] = function(arg0)
  UI.HoveredElement = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y - UI.DB[arg0].properties.tab_height.value * SCALE_Y - UI.DB[arg0].properties.title_height.value * SCALE_Y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height + UI.DB[arg0].properties.tab_height.value * SCALE_Y + UI.DB[arg0].properties.title_height.value * SCALE_Y) and arg0 or UI.HoveredElement
  dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, UI.DB[arg0].colors[1], UI.postGUI)
  if UI.DB[arg0].properties.title_shown.value then
    dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y - UI.DB[arg0].properties.tab_height.value * SCALE_Y - UI.DB[arg0].properties.title_height.value * SCALE_Y, UI.DB[arg0].dimensions.width, UI.DB[arg0].properties.title_height.value * SCALE_Y, tocolor(0, 0, 0), 5, {
      up = {left = true, right = true},
      down = {left = false, right = false}
    }, UI.postGUI)
    dxDrawText(UI.DB[arg0].data.selected_tab and UI.DB[UI.DB[arg0].data.selected_tab].title or UI.DB[arg0].text[language], UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y - UI.DB[arg0].properties.tab_height.value * SCALE_Y - UI.DB[arg0].properties.title_height.value * SCALE_Y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y - UI.DB[arg0].properties.tab_height.value - 3, tocolor(255, 255, 255), UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, false, UI.postGUI)
  end
  if 0 < #UI.DB[arg0].data.visible_tabs then
    UI.DB[arg0].data.hovered_tab = nil
    dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y - UI.DB[arg0].properties.tab_height.value * SCALE_Y - 2 * SCALE_Y, UI.DB[arg0].dimensions.width, UI.DB[arg0].properties.tab_height.value * SCALE_Y, UI.DB[arg0].properties.tabs_bar_color.value, 4, UI.postGUI)
    for forvar18, forvar19 in ipairs(UI.DB[arg0].data.visible_tabs) do
      -- [Vortex fix] the Owl decompiler lost the per-tab X offset accumulation,
      -- so every tab (bg / label / hover check / underline) drew into the FIRST
      -- slot -- labels stacked into garbage and tab clicks always hit tab 1.
      local slotW = (UI.DB[arg0].dimensions.width - 5 * (#UI.DB[arg0].data.visible_tabs + 1) * SCALE_Y) / #UI.DB[arg0].data.visible_tabs
      local slotX = UI.DB[arg0].dimensions.x + 5 * SCALE_Y + (slotW + 5 * SCALE_Y) * (forvar18 - 1)
      local slotY = UI.DB[arg0].dimensions.y - UI.DB[arg0].properties.tab_height.value * SCALE_Y - 2 * SCALE_Y
      UI.DB[arg0].data.hovered_tab = isMouseInPosition(slotX, slotY, slotW, UI.DB[arg0].properties.tab_height.value * SCALE_Y) and forvar19 or UI.DB[arg0].data.hovered_tab
      dxDrawRoundedRectangle(slotX, slotY + 5 * SCALE_Y, slotW, UI.DB[arg0].properties.tab_height.value * SCALE_Y - 10 * SCALE_Y, UI.DB[forvar19].properties.Disabled.value ~= "True" and UI.DB[arg0].properties.Disabled.value ~= "True" and (UI.DB[arg0].data.selected_tab == forvar19 and UI.DB[arg0].properties.tab_selected_color.value or isMouseInPosition(slotX, slotY, slotW, UI.DB[arg0].properties.tab_height.value * SCALE_Y) and UI.DB[arg0].properties.tab_hovered_color.value or UI.DB[arg0].properties.tab_color.value) or UI.DB[arg0].properties.tab_disabled_color.value, 4, UI.postGUI)
      if UI.DB[arg0].data.selected_tab == forvar19 then
        line_w = anim(UI.DB[arg0].animation[1], 200, 0, 0, 0, 0, slotW / 2, 0, 0, 0, "Linear")
        dxDrawRectangle(slotX + (slotW - line_w) / 2, slotY + 5 * SCALE_Y + (UI.DB[arg0].properties.tab_height.value * SCALE_Y - 10 * SCALE_Y), line_w, 1, theme.COLORS.primary, UI.postGUI)
      end
      dxDrawText(UI.DB[forvar19].text[language], slotX, slotY + 5 * SCALE_Y, slotX + slotW, slotY + 5 * SCALE_Y + (UI.DB[arg0].properties.tab_height.value * SCALE_Y - 10 * SCALE_Y), UI.DB[forvar19].properties.Disabled.value ~= "True" and UI.DB[arg0].properties.Disabled.value ~= "True" and (isMouseInPosition(slotX, slotY, slotW, UI.DB[arg0].properties.tab_height.value * SCALE_Y) and UI.DB[arg0].properties.tab_text_hovered_color.value or UI.DB[arg0].properties.tab_text_color.value) or UI.DB[arg0].properties.tab_text_disabled_color.value, UI.DB[forvar19].font.size, UI.DB[forvar19].font.name, UI.DB[forvar19].align.X, UI.DB[forvar19].align.Y, true, false, UI.postGUI)
      UI.isDraw[forvar19] = UI.DB[arg0].data.selected_tab == forvar19
    end
  else
    dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y - UI.DB[arg0].properties.tab_height.value * SCALE_Y + 1, UI.DB[arg0].dimensions.width, UI.DB[arg0].properties.tab_height.value * SCALE_Y, UI.DB[arg0].colors[1], UI.postGUI)
  end
end
function updateVisibility()
  if getElementType(source) == "ui-tab" and getElementType(getElementParent(source)) == "ui-tabpanel" then
    for forvar4, forvar5 in ipairs(getElementChildren(getElementParent(source), "ui-tab")) do
      if (eventName == "onClientElementDestroy" and forvar5 ~= source or eventName == "onClientUIVisibilityChange") and UI.DB[forvar5].visible then
        table.insert({}, forvar5)
      end
    end
    UI.DB[getElementParent(source)].data.visible_tabs = {}
  end
end
addEventHandler("onClientElementDestroy", resourceRoot, updateVisibility)
addEventHandler("onClientUIVisibilityChange", resourceRoot, updateVisibility)
addEventHandler("onClientUIClick", resourceRoot, function()
  if getElementType(source) == "ui-tabpanel" then
    UI.DB[source].animation[1] = getTickCount()
  end
end)
