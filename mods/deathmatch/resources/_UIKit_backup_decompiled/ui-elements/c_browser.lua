-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateBrowser(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
  UI.DB[createElement("ui-browser")] = {
    visible = true,
    related_dimensions = {
      x = arg0,
      y = arg1,
      width = arg2,
      height = arg3
    },
    text = text,
    data = {
      browser = createBrowser(arg2, arg3, arg4, arg5)
    },
    font = {name = dxFont, size = 1},
    align = {X = "center", Y = "center"},
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
      }
    }
  }
  addUIElement(createElement("ui-browser"), arg6, sourceResource)
  return (createElement("ui-browser"))
end
function uiGetBrowser(arg0)
  assert(isUIElement(arg0, "browser"), "Bad argument @ 'uiGetBrowser' [Expected ui-browser at argument 1, got " .. (isElement(arg0) and getElementType(arg0) or type(arg0)) .. "]")
  return UI.DB[arg0].data.browser
end
function clientClickEvent(arg0, arg1)
  if not UI.FocusElement then
    return
  end
  if getElementType(UI.FocusElement) == "ui-browser" then
    if arg1 == "down" then
      injectBrowserMouseDown(UI.DB[UI.FocusElement].data.browser, arg0)
    else
      injectBrowserMouseUp(UI.DB[UI.FocusElement].data.browser, arg0)
    end
  end
end
function clientKeyEvent(arg0)
  if not UI.FocusElement then
    return
  end
  if getElementType(UI.FocusElement) == "ui-browser" then
    if arg0 == "mouse_wheel_down" then
      injectBrowserMouseWheel(UI.DB[UI.FocusElement].data.browser, -40, 0)
    elseif arg0 == "mouse_wheel_up" then
      injectBrowserMouseWheel(UI.DB[UI.FocusElement].data.browser, 40, 0)
    end
  end
end
function cursorMoveEvent(arg0, arg1, arg2, arg3)
  if not UI.FocusElement then
    return
  end
  if getElementType(UI.FocusElement) == "ui-browser" then
    injectBrowserMouseMove(UI.DB[UI.FocusElement].data.browser, arg2 - UI.DB[UI.FocusElement].dimensions.x, arg3 - UI.DB[UI.FocusElement].dimensions.y)
  end
end
addEventHandler("onClientUIFocus", resourceRoot, function()
  if getElementType(source) == "ui-browser" then
    addEventHandler("onClientCursorMove", root, cursorMoveEvent)
    addEventHandler("onClientClick", root, clientClickEvent)
    addEventHandler("onClientKey", root, clientKeyEvent)
    focusBrowser(UI.DB[source].data.browser)
    guiSetInputMode("no_binds")
  end
end)
addEventHandler("onClientUIBlur", resourceRoot, function()
  if getElementType(source) == "ui-browser" then
    removeEventHandler("onClientCursorMove", root, cursorMoveEvent)
    removeEventHandler("onClientClick", root, clientClickEvent)
    removeEventHandler("onClientKey", root, clientKeyEvent)
    focusBrowser(nil)
    guiSetInputMode("allow_binds")
  end
end)
UI.getDrawFunction["ui-browser"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  dxDrawImage(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, UI.DB[arg0].data.browser, 0, 0, 0, tocolor(255, 255, 255, 255), UI.postGUI)
end
