-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateDialog(arg0, arg1, arg2, arg3, arg4, arg5)
  arg0 = arg0 or (ref_sx - arg2) / 2
  arg1 = arg1 or (ref_sy - arg3) / 2
  UI.DB[createElement("ui-dialog")] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = arg4,
    colors = {
      arg5 or tocolor(0, 0, 0, 220)
    },
    align = {X = "center", Y = "center"},
    font = {name = dxFont, size = 1},
    data = {
      left_button = {
        text = "Accept",
        color = tocolor(0, 163, 65, 255),
        align = {X = "center", Y = "center"},
        font = {name = dxFont, size = 1},
        click = false,
        callback = ref(function()
        end)
      },
      right_button = {
        text = "Cancel",
        color = tocolor(237, 24, 0, 255),
        align = {X = "center", Y = "center"},
        font = {name = dxFont, size = 1},
        click = false,
        callback = ref(function()
        end)
      }
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
      top_line_color = {
        value = tocolor(10, 10, 10, 255),
        valueType = "number"
      },
      top_bar_height = {value = 30, valueType = "number"},
      top_bar_color = {
        value = tocolor(0, 0, 0, 255),
        valueType = "number"
      },
      right_button_hover_color = {
        value = tocolor(237, 24, 0, 230),
        valueType = "number"
      },
      right_button_click_color = {
        value = tocolor(237, 24, 0, 240),
        valueType = "number"
      },
      left_button_hover_color = {
        value = tocolor(0, 163, 65, 230),
        valueType = "number"
      },
      left_button_click_color = {
        value = tocolor(0, 163, 65, 240),
        valueType = "number"
      },
      buttons_height = {value = 30, valueType = "number"},
      movable = {value = true, valueType = "boolean"}
    }
  }
  addUIElement(createElement("ui-dialog"), nil, sourceResource)
  return (createElement("ui-dialog"))
end
function uiDialogSetRightButtonCallback(arg0, arg1)
  assert(isUIElement(arg0, "dialog"), "Bad argument @ 'uiDialogSetRightButtonCallback' [Expected ui-dialog at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].data.right_button.callback = arg1
  return true
end
function uiDialogSetLeftButtonCallback(arg0, arg1)
  assert(isUIElement(arg0, "dialog"), "Bad argument @ 'uiDialogSetLeftButtonCallback' [Expected ui-dialog at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].data.left_button.callback = arg1
  return true
end
function uiDialogSetRightButtonText(arg0, arg1)
  assert(isUIElement(arg0, "dialog"), "Bad argument @ 'uiDialogSetRightButtonText' [Expected ui-dialog at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].data.right_button.text = arg1
  return true
end
function uiDialogSetLeftButtonText(arg0, arg1)
  assert(isUIElement(arg0, "dialog"), "Bad argument @ 'uiDialogSetLeftButtonText' [Expected ui-dialog at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  UI.DB[arg0].data.left_button.text = arg1
  return true
end
function uiDialogGetRightButtonCallback(arg0)
  assert(isUIElement(arg0, "dialog"), "Bad argument @ 'uiDialogGetRightButtonCallback' [Expected ui-dialog at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.right_button.callback
end
function uiDialogGetLeftButtonCallback(arg0)
  assert(isUIElement(arg0, "dialog"), "Bad argument @ 'uiDialogGetLeftButtonCallback' [Expected ui-dialog at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.left_button.callback
end
function uiDialogGetRightButtonText(arg0)
  assert(isUIElement(arg0, "dialog"), "Bad argument @ 'uiDialogGetRightButtonText' [Expected ui-dialog at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.right_button.text
end
function uiDialogGetLeftButtonText(arg0)
  assert(isUIElement(arg0, "dialog"), "Bad argument @ 'uiDialogGetLeftButtonText' [Expected ui-dialog at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.left_button.text
end
UI.getDrawFunction["ui-dialog"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].properties.top_bar_height.value + 8)
  dxDrawRectangle(UI.DB[arg0].dimensions.x + 8, UI.DB[arg0].dimensions.y + 8 - 8, UI.DB[arg0].dimensions.width - 8 * 2, 8, UI.DB[arg0].properties.top_bar_color.value, UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x + 8, UI.DB[arg0].dimensions.y + 8, UI.DB[arg0].dimensions.width - 8 * 2, UI.DB[arg0].properties.top_bar_height.value, UI.DB[arg0].properties.top_bar_color.value, UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x + 8 - 8, UI.DB[arg0].dimensions.y + 8, 8, UI.DB[arg0].properties.top_bar_height.value, UI.DB[arg0].properties.top_bar_color.value, UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x + 8 + (UI.DB[arg0].dimensions.width - 8 * 2), UI.DB[arg0].dimensions.y + 8, 8, UI.DB[arg0].properties.top_bar_height.value, UI.DB[arg0].properties.top_bar_color.value, UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x + 8, UI.DB[arg0].dimensions.y + 8 + UI.DB[arg0].properties.top_bar_height.value, UI.DB[arg0].dimensions.width - 8 * 2, UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value - UI.DB[arg0].properties.top_bar_height.value, UI.DB[arg0].colors[1], UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x + 8 - 8, UI.DB[arg0].dimensions.y + 8 + UI.DB[arg0].properties.top_bar_height.value, 8, UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value - UI.DB[arg0].properties.top_bar_height.value, UI.DB[arg0].colors[1], UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x + 8 + (UI.DB[arg0].dimensions.width - 8 * 2), UI.DB[arg0].dimensions.y + 8 + UI.DB[arg0].properties.top_bar_height.value, 8, UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value - UI.DB[arg0].properties.top_bar_height.value, UI.DB[arg0].colors[1], UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x + 8, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2), (UI.DB[arg0].dimensions.width - 8 * 2) / 2, 8, ({
    right = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).right and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.right_button_click_color.value or UI.DB[arg0].properties.right_button_hover_color.value) or UI.DB[arg0].data.right_button.color,
    left = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).left and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.left_button_click_color.value or UI.DB[arg0].properties.left_button_hover_color.value) or UI.DB[arg0].data.left_button.color
  }).left, UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x + 8 + (UI.DB[arg0].dimensions.width - 8 * 2) / 2, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2), (UI.DB[arg0].dimensions.width - 8 * 2) / 2, 8, ({
    right = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).right and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.right_button_click_color.value or UI.DB[arg0].properties.right_button_hover_color.value) or UI.DB[arg0].data.right_button.color,
    left = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).left and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.left_button_click_color.value or UI.DB[arg0].properties.left_button_hover_color.value) or UI.DB[arg0].data.left_button.color
  }).right, UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2, UI.DB[arg0].properties.buttons_height.value, ({
    right = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).right and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.right_button_click_color.value or UI.DB[arg0].properties.right_button_hover_color.value) or UI.DB[arg0].data.right_button.color,
    left = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).left and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.left_button_click_color.value or UI.DB[arg0].properties.left_button_hover_color.value) or UI.DB[arg0].data.left_button.color
  }).left, UI.postGUI)
  dxDrawRectangle(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2, UI.DB[arg0].properties.buttons_height.value, ({
    right = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).right and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.right_button_click_color.value or UI.DB[arg0].properties.right_button_hover_color.value) or UI.DB[arg0].data.right_button.color,
    left = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).left and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.left_button_click_color.value or UI.DB[arg0].properties.left_button_hover_color.value) or UI.DB[arg0].data.left_button.color
  }).right, UI.postGUI)
  dxDrawCircle(UI.DB[arg0].dimensions.x + 8, UI.DB[arg0].dimensions.y + 8, 8, 180, 270, UI.DB[arg0].properties.top_bar_color.value, UI.DB[arg0].properties.top_bar_color.value, 7, 1, UI.postGUI)
  dxDrawCircle(UI.DB[arg0].dimensions.x + 8 + (UI.DB[arg0].dimensions.width - 8 * 2), UI.DB[arg0].dimensions.y + 8, 8, 270, 360, UI.DB[arg0].properties.top_bar_color.value, UI.DB[arg0].properties.top_bar_color.value, 7, 1, UI.postGUI)
  dxDrawCircle(UI.DB[arg0].dimensions.x + 8 + (UI.DB[arg0].dimensions.width - 8 * 2), UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2), 8, 0, 90, ({
    right = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).right and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.right_button_click_color.value or UI.DB[arg0].properties.right_button_hover_color.value) or UI.DB[arg0].data.right_button.color,
    left = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).left and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.left_button_click_color.value or UI.DB[arg0].properties.left_button_hover_color.value) or UI.DB[arg0].data.left_button.color
  }).right, ({
    right = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).right and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.right_button_click_color.value or UI.DB[arg0].properties.right_button_hover_color.value) or UI.DB[arg0].data.right_button.color,
    left = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).left and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.left_button_click_color.value or UI.DB[arg0].properties.left_button_hover_color.value) or UI.DB[arg0].data.left_button.color
  }).right, 7, 1, UI.postGUI)
  dxDrawCircle(UI.DB[arg0].dimensions.x + 8, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2), 8, 90, 180, ({
    right = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).right and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.right_button_click_color.value or UI.DB[arg0].properties.right_button_hover_color.value) or UI.DB[arg0].data.right_button.color,
    left = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).left and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.left_button_click_color.value or UI.DB[arg0].properties.left_button_hover_color.value) or UI.DB[arg0].data.left_button.color
  }).left, ({
    right = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).right and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.right_button_click_color.value or UI.DB[arg0].properties.right_button_hover_color.value) or UI.DB[arg0].data.right_button.color,
    left = ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).left and (({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).leftClick and UI.DB[arg0].properties.left_button_click_color.value or UI.DB[arg0].properties.left_button_hover_color.value) or UI.DB[arg0].data.left_button.color
  }).left, 7, 1, UI.postGUI)
  dxDrawLine(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + UI.DB[arg0].properties.top_bar_height.value, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + 8 + UI.DB[arg0].properties.top_bar_height.value, UI.DB[arg0].properties.top_line_color.value, 2, UI.postGUI)
  dxDrawText(UI.DB[arg0].text, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + 8 + UI.DB[arg0].properties.top_bar_height.value, tocolor(255, 255, 255, 255), UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, false, UI.postGUI)
  dxDrawText(UI.DB[arg0].data.right_button.text, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, tocolor(255, 255, 255, 255), UI.DB[arg0].data.right_button.font.size, UI.DB[arg0].data.right_button.font.name, UI.DB[arg0].data.right_button.align.X, UI.DB[arg0].data.right_button.align.Y, true, false, UI.postGUI)
  dxDrawText(UI.DB[arg0].data.left_button.text, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, tocolor(255, 255, 255, 255), UI.DB[arg0].data.left_button.font.size, UI.DB[arg0].data.left_button.font.name, UI.DB[arg0].data.left_button.align.X, UI.DB[arg0].data.left_button.align.Y, true, false, UI.postGUI)
  if ({
    right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
    left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
    leftClick = getKeyState("mouse1")
  }).leftClick then
    if ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).left then
      if not UI.DB[arg0].data.left_button.click then
        UI.DB[arg0].data.left_button.click = true
      end
    elseif ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).right and not UI.DB[arg0].data.right_button.click then
      UI.DB[arg0].data.right_button.click = true
    end
  else
    if ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).left then
      if UI.DB[arg0].data.left_button.click then
        deref(UI.DB[arg0].data.left_button.callback)()
        triggerEvent("onClientUIDialogButtonClick", arg0, "left")
        UI.DB[arg0].visible = false
      end
    elseif ({
      right = isMouseInPosition(UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width / 2 + 1, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      left = isMouseInPosition(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y + 8 + (UI.DB[arg0].dimensions.height - 8 * 2 - UI.DB[arg0].properties.buttons_height.value), UI.DB[arg0].dimensions.width / 2 - 1, UI.DB[arg0].properties.buttons_height.value + 8),
      leftClick = getKeyState("mouse1")
    }).right and UI.DB[arg0].data.right_button.click then
      deref(UI.DB[arg0].data.right_button.callback)()
      triggerEvent("onClientUIDialogButtonClick", arg0, "right")
      UI.DB[arg0].visible = false
    end
    if UI.DB[arg0].data.left_button.click then
      UI.DB[arg0].data.left_button.click = false
    elseif UI.DB[arg0].data.right_button.click then
      UI.DB[arg0].data.right_button.click = false
    end
  end
end
