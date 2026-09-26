-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

moveTemp = {}
function UI.updateDrawingList()
  UI.DrawElements = {}
  for forvar4 = 1, #UI.Elements do
    if UI.DB[UI.Elements[forvar4]].visible then
      if ({})[var0(UI.Elements[forvar4])] or false then
        UI.DrawElements[#UI.DrawElements + 1] = UI.Elements[forvar4]
        ;({})[UI.Elements[forvar4]] = true
      end
    end
  end
end
function UI.drawing()
  UI.HoveredElement = false
  var0 = false
  var1 = false
  for forvar3 = 1, #UI.DrawElements do
    if var2(UI.DrawElements[forvar3]) then
      if UI.DB[UI.DrawElements[forvar3]].visible then
        if UI.isDraw[var3(UI.DrawElements[forvar3])] or false then
          if var4(UI.DrawElements[forvar3]) ~= "ui-tab" then
            var0 = isMouseInPosition(UI.DB[UI.DrawElements[forvar3]].dimensions.x, UI.DB[UI.DrawElements[forvar3]].dimensions.y, UI.DB[UI.DrawElements[forvar3]].dimensions.width, UI.DB[UI.DrawElements[forvar3]].dimensions.height) and UI.DrawElements[forvar3] or var0
          end
          if var5() and (var6() >= 1 or var6() <= 0 or var6() >= 1 or var6() <= 0) and UI.DB[UI.DrawElements[forvar3]].state == "clicked" and UI.DB[UI.DrawElements[forvar3]].state ~= "normal" then
            UI.DB[UI.DrawElements[forvar3]].state = "normal"
            if isEventHandlerAdded("onClientCursorMove", root, moveElement) then
              removeEventHandler("onClientCursorMove", root, moveElement)
              moveTemp = {}
            end
          end
          if type(UI.getDrawFunction[var4(UI.DrawElements[forvar3])]) == "function" then
            UI.getDrawFunction[var4(UI.DrawElements[forvar3])](UI.DrawElements[forvar3])
            UI.isDraw[UI.DrawElements[forvar3]] = true
            var1 = true
          end
          UI.TempDisabled[UI.DrawElements[forvar3]] = UI.DB[UI.DrawElements[forvar3]].properties.Disabled.value == "True" or UI.TempDisabled[var3(UI.DrawElements[forvar3])]
        else
        end
      else
      end
      if not false then
        UI.isDraw[UI.DrawElements[forvar3]] = false
        if UI.FocusElement == UI.DrawElements[forvar3] then
          UI.FocusElement = false
          UI.DB[UI.DrawElements[forvar3]].state = "normal"
          triggerEvent("onClientUIBlur", UI.DrawElements[forvar3])
        end
        if UI.HoveredElement == UI.DrawElements[forvar3] then
          UI.HoveredElement = false
        end
      end
    end
  end
  if var0 ~= UI.TempHoveredElement then
    if UI.TempHoveredElement and var2(UI.TempHoveredElement) then
      UI.DB[UI.TempHoveredElement].data.leaveTick = getTickCount()
      triggerEvent("onClientUIMouseLeave", UI.TempHoveredElement)
    end
    UI.TempHoveredElement = var0
    if var0 then
      if var4(var0) == "ui-edit" and UI.FocusElement ~= var0 then
        UI.DB[var0].animation = {
          getTickCount(),
          true
        }
      end
      UI.DB[var0].data.enterTick = getTickCount()
      triggerEvent("onClientUIMouseEnter", var0)
    end
  end
  if not var1 then
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
function UI.click(arg0, arg1, arg2, arg3)
  if arg0 == "left" then
    if UI.HoveredElement then
      if isTimer(var0) then
        killTimer(var0)
      end
      if isTimer(var1) then
        killTimer(var1)
      end
      if isUIDisabled(UI.HoveredElement) then
        return
      end
      if var3(UI.FocusElement) then
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
          if var2(UI.HoveredElement) == "ui-edit" then
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
          elseif var2(UI.HoveredElement) == "ui-combobox" then
            if isMouseInPosition(UI.DB[UI.HoveredElement].dimensions.x + (UI.DB[UI.HoveredElement].dimensions.width - UI.DB[UI.HoveredElement].dimensions.width / 8), UI.DB[UI.HoveredElement].dimensions.y, UI.DB[UI.HoveredElement].dimensions.width / 8, UI.DB[UI.HoveredElement].dimensions.height) then
              UI.DB[UI.HoveredElement].data.visible = not UI.DB[UI.HoveredElement].data.visible
              uiSetVisible(UI.DB[UI.HoveredElement].scrollbar.element, #UI.DB[UI.HoveredElement].data.items > UI.DB[UI.HoveredElement].properties.items_per_page.value and not UI.DB[UI.HoveredElement].data.visible or false)
              UI.VisibleList = UI.HoveredElement
              uiBringToFront(UI.HoveredElement)
            end
          elseif var2(UI.HoveredElement) == "ui-switch" or var2(UI.HoveredElement) == "ui-checkbox" then
            UI.DB[UI.HoveredElement].data.selected = not UI.DB[UI.HoveredElement].data.selected
            UI.DB[UI.HoveredElement].animation[1] = getTickCount()
            playSound(":UIKit/sounds/click2.wav")
          elseif var2(UI.HoveredElement) == "ui-radiobutton" then
            if UI.HoveredElement ~= UI.SelectedRadio[var4(UI.HoveredElement)] and UI.SelectedRadio[var4(UI.HoveredElement)] then
              UI.DB[UI.SelectedRadio[var4(UI.HoveredElement)]].animation[1] = getTickCount()
            end
            UI.DB[UI.HoveredElement].animation[1] = getTickCount()
            UI.SelectedRadio[var4(UI.HoveredElement)] = UI.SelectedRadio[var4(UI.HoveredElement)] ~= UI.HoveredElement and UI.HoveredElement
          elseif var2(UI.HoveredElement) == "ui-memo" then
            removeEventHandler("onClientCursorMove", root, moveCursorForShading)
            toggleControl("chatbox", false)
          elseif var2(UI.HoveredElement) == "ui-window" or var2(UI.HoveredElement) == "ui-dialog" then
            removeEventHandler("onClientCursorMove", root, moveElement)
            moveTemp = {}
          elseif var2(UI.HoveredElement) == "ui-tabpanel" and UI.DB[UI.HoveredElement].data.hovered_tab and UI.DB[UI.DB[UI.HoveredElement].data.hovered_tab].properties.Disabled.value ~= "True" and UI.DB[UI.HoveredElement].properties.Disabled.value ~= "True" and UI.DB[UI.HoveredElement].data.selected_tab ~= UI.DB[UI.HoveredElement].data.hovered_tab then
            uiSetSelectedTab(UI.HoveredElement, UI.DB[UI.HoveredElement].data.hovered_tab)
          end
          if UI.DraggedElement then
            removeEventHandler("onClientCursorMove", root, dragElement)
            if dragTemp then
              UI.DB[UI.DraggedElement].dimensions.x = unpack(dragTemp)
              UI.DB[UI.DraggedElement].dimensions.y = unpack(dragTemp)
            end
            triggerEvent("onClientUIDragEnd", UI.DraggedElement, UI.HoveredElement)
            UI.DraggedElement = nil
          end
        else
          if var2(UI.HoveredElement) == "ui-gridlist" then
            if not UI.DB[UI.HoveredElement].data.hovered_row then
              UI.DB[UI.HoveredElement].data.selected_row = -1
              triggerEvent("onClientUIGridlistItemSelected", UI.HoveredElement, UI.DB[UI.HoveredElement].data.selected_row)
            elseif UI.DB[UI.HoveredElement].data.selected_row ~= UI.DB[UI.HoveredElement].data.hovered_row then
              UI.DB[UI.HoveredElement].data.selected_row = UI.DB[UI.HoveredElement].data.hovered_row
              triggerEvent("onClientUIGridlistItemSelected", UI.HoveredElement, UI.DB[UI.HoveredElement].data.selected_row)
            end
          elseif var2(UI.HoveredElement) == "ui-checklist" then
            if UI.DB[UI.HoveredElement].data.hovered_row and UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row] then
              UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].selected = not UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].selected
              UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].animation[1] = getTickCount()
            end
          elseif var2(UI.HoveredElement) == "ui-menu" then
            if UI.DB[UI.HoveredElement].data.hovered_row and UI.DB[UI.HoveredElement].data.selected_row ~= UI.DB[UI.HoveredElement].data.hovered_row then
              UI.DB[UI.HoveredElement].data.selected_row = UI.DB[UI.HoveredElement].data.hovered_row
              if UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.selected_row] and UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.selected_row].toggle_element then
                uiSetVisible(UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.selected_row] and UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.selected_row].toggle_element, false)
              end
              if UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row] and UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].toggle_element then
                uiSetVisible(UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row] and UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].toggle_element, true)
              end
              triggerEvent("onClientUIMenuSelectChange", UI.HoveredElement, UI.DB[UI.HoveredElement].data.hovered_row, UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row] and UI.DB[UI.HoveredElement].data.rows[UI.DB[UI.HoveredElement].data.hovered_row].toggle_element)
            end
          elseif var3(UI.VisibleList) and var2(UI.VisibleList) == "ui-combobox" and UI.HoveredElement ~= UI.DB[UI.VisibleList].scrollbar.element and not UI.DB[UI.VisibleList].data.hovered_item then
            if not isMouseInPosition(UI.DB[UI.VisibleList].dimensions.x + (UI.DB[UI.VisibleList].dimensions.width - UI.DB[UI.VisibleList].dimensions.width / 8), UI.DB[UI.VisibleList].dimensions.y, UI.DB[UI.VisibleList].dimensions.width / 8, UI.DB[UI.VisibleList].dimensions.height) and UI.DB[UI.VisibleList].data.visible then
              UI.DB[UI.VisibleList].data.visible = false
              UI.DB[UI.VisibleList].data.selected_item = -1
              uiSetVisible(UI.DB[UI.VisibleList].scrollbar.element, false)
              UI.VisibleList = false
            end
          elseif var2(UI.HoveredElement) == "ui-scrollbar" then
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
          elseif var2(UI.HoveredElement) == "ui-edit" then
            UI.DB[UI.HoveredElement].data.shading[1] = getCaretFromCursorPosition(UI.DB[UI.HoveredElement].dimensions.x + 7, UI.DB[UI.HoveredElement].text, arg2, UI.HoveredElement)
            UI.DB[UI.HoveredElement].data.shading[2] = getCaretFromCursorPosition(UI.DB[UI.HoveredElement].dimensions.x + 7, UI.DB[UI.HoveredElement].text, arg2, UI.HoveredElement)
            UI.DB[UI.HoveredElement].data.shading[3] = getCaretFromCursorPosition(UI.DB[UI.HoveredElement].dimensions.x + 7, UI.DB[UI.HoveredElement].text, arg2, UI.HoveredElement)
            addEventHandler("onClientCursorMove", root, moveCursor)
            toggleControl("chatbox", false)
          elseif var2(UI.HoveredElement) == "ui-memo" then
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
          elseif (var2(UI.HoveredElement) == "ui-window" or var2(UI.HoveredElement) == "ui-dialog") and arg1 == "down" and UI.DB[UI.HoveredElement].properties.movable.value then
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
      if arg1 == "down" and UI.DB[UI.HoveredElement].properties.DisableFocus.value ~= "False" then
        uiBringToFront(UI.HoveredElement)
      end
      UI.DB[UI.HoveredElement].state = arg1 == "down" and "clicked" or UI.DB[UI.HoveredElement].state
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
function UI.doubleclick(arg0, arg1, arg2)
  if arg0 == "left" and UI.HoveredElement then
    if isUIDisabled(UI.HoveredElement) then
      return
    end
    if var0(UI.HoveredElement) == "ui-edit" then
      UI.DB[UI.HoveredElement].data.shading[1] = 1
      UI.DB[UI.HoveredElement].data.shading[2] = utfLen(UI.DB[UI.HoveredElement].text) + 1
      UI.DB[UI.HoveredElement].data.shading[3] = 1
      uiEditSetCaretIndex(UI.HoveredElement, utfLen(UI.DB[UI.HoveredElement].text) + 1)
    elseif var0(UI.HoveredElement) == "ui-memo" then
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
  if UI.FocusElement and var0(UI.FocusElement) == "ui-edit" and not UI.DB[UI.FocusElement].data.readonly then
    if not var1() then
      return
    end
    if uiEditGetShadedText(UI.FocusElement) then
      UI.DB[UI.FocusElement].data.shading = {1, 1}
      uiSetText(UI.FocusElement, utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.shading[1] - 1) .. arg0 .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.shading[2], utfLen(UI.DB[UI.FocusElement].text)))
      triggerEvent("onClientUIChanged", UI.FocusElement)
      uiEditSetCaretIndex(UI.FocusElement, utfLen(utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.shading[1] - 1) .. arg0) + 1)
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
  elseif UI.FocusElement and var0(UI.FocusElement) == "ui-memo" and not UI.DB[UI.FocusElement].data.readonly then
    if not var1() then
      return
    end
    if replaceShadedText(UI.FocusElement, arg0) then
      triggerEvent("onClientUITextChange", UI.FocusElement)
      return
    end
    ;(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine] = utfSub((UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""), 1, UI.DB[UI.FocusElement].data.caret - 1) .. arg0 .. utfSub((UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""), UI.DB[UI.FocusElement].data.caret, utfLen((UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine]))
    uiSetText(UI.FocusElement, table.concat(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    }, "\n"):gsub("" .. newLinePrefix, ""))
    UI.DB[UI.FocusElement].data.caret = UI.DB[UI.FocusElement].data.caret + 1
    if uiMemoGetCaretIndex(UI.FocusElement) ~= uiMemoGetCaretIndex(UI.FocusElement) then
      triggerEvent("onClientUICaretPositionChange", UI.FocusElement, uiMemoGetCaretIndex(UI.FocusElement))
    end
  end
end)
addEvent("ui-returnClipBoard", true)
addEventHandler("ui-returnClipBoard", localPlayer, function(arg0)
  if UI.FocusElement and var0(UI.FocusElement) == "ui-edit" and not UI.DB[UI.FocusElement].data.readonly then
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
  elseif UI.FocusElement and var0(UI.FocusElement) == "ui-memo" and not UI.DB[UI.FocusElement].data.readonly then
    arg0 = arg0:gsub("" .. newLinePrefix, "\n")
    if replaceShadedText(UI.FocusElement, arg0) then
      triggerEvent("onClientUITextChange", UI.FocusElement)
      return
    end
    ;(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine] = utfSub((UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""), 1, UI.DB[UI.FocusElement].data.caret - 1) .. arg0 .. utfSub((UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""), UI.DB[UI.FocusElement].data.caret, utfLen((UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine]))
    uiSetText(UI.FocusElement, table.concat(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    }, "\n"):gsub("" .. newLinePrefix, ""))
    UI.DB[UI.FocusElement].data.showtext = table.concat(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    }, "\n", UI.DB[UI.FocusElement].data.line_i, (math.min(#(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    }), UI.DB[UI.FocusElement].data.line_i + math.floor(UI.DB[UI.FocusElement].dimensions.height / dxGetFontHeight(UI.DB[UI.FocusElement].font.size, UI.DB[UI.FocusElement].font.name)) + 1))):gsub("" .. newLinePrefix, "")
    UI.DB[UI.FocusElement].data.caret = utfLen((utfSub((UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix):find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
      (UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix))
    })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""), 1, UI.DB[UI.FocusElement].data.caret - 1) .. arg0):gsub("" .. newLinePrefix, "")) + 1
    if uiMemoGetCaretIndex(UI.FocusElement) ~= uiMemoGetCaretIndex(UI.FocusElement) then
      triggerEvent("onClientUICaretPositionChange", UI.FocusElement, uiMemoGetCaretIndex(UI.FocusElement))
    end
  end
end)
function moveCaret(arg0, arg1)
  if UI.FocusElement and var0(UI.FocusElement) == "ui-edit" then
    if arg1 == "down" then
      if arg0 == "arrow_r" then
        uiEditSetCaretIndex(UI.FocusElement, math.min(UI.DB[UI.FocusElement].data.caret + 1, utfLen(UI.DB[UI.FocusElement].text) + 1))
        if isTimer(var1) then
          killTimer(var1)
        end
        var1 = setTimer(function(arg0)
          uiEditSetCaretIndex(arg0, math.min(UI.DB[arg0].data.caret + 1, utfLen(UI.DB[arg0].text) + 1))
        end, 150, 0, UI.FocusElement)
      elseif arg0 == "arrow_l" then
        uiEditSetCaretIndex(UI.FocusElement, math.max(UI.DB[UI.FocusElement].data.caret - 1, 1))
        if isTimer(var1) then
          killTimer(var1)
        end
        var1 = setTimer(function(arg0)
          uiEditSetCaretIndex(arg0, math.max(UI.DB[arg0].data.caret - 1, 1))
        end, 150, 0, UI.FocusElement)
      end
    elseif isTimer(var1) then
      killTimer(var1)
    end
  elseif UI.FocusElement and var0(UI.FocusElement) == "ui-memo" then
    if arg1 == "down" then
      if arg0 == "arrow_r" then
        UI.DB[UI.FocusElement].data.caret = math.min(UI.DB[UI.FocusElement].data.caret + 1, utfLen(((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""))) + 1)
        if isTimer(var1) then
          killTimer(var1)
        end
        var1 = setTimer(function(arg0)
          UI.DB[arg0].data.caret = math.min(UI.DB[arg0].data.caret + 1, utfLen(var0) + 1)
          if uiMemoGetCaretIndex(arg0) ~= uiMemoGetCaretIndex(arg0) then
            triggerEvent("onClientUICaretPositionChange", arg0, uiMemoGetCaretIndex(arg0))
          end
        end, 150, 0, UI.FocusElement)
      elseif arg0 == "arrow_l" then
        UI.DB[UI.FocusElement].data.caret = math.max(UI.DB[UI.FocusElement].data.caret - 1, 1)
        if isTimer(var1) then
          killTimer(var1)
        end
        var1 = setTimer(function(arg0)
          UI.DB[arg0].data.caret = math.max(UI.DB[arg0].data.caret - 1, 1)
          if uiMemoGetCaretIndex(arg0) ~= uiMemoGetCaretIndex(arg0) then
            triggerEvent("onClientUICaretPositionChange", arg0, uiMemoGetCaretIndex(arg0))
          end
        end, 150, 0, UI.FocusElement)
      elseif arg0 == "arrow_u" then
        UI.DB[UI.FocusElement].data.caretLine = math.max(UI.DB[UI.FocusElement].data.caretLine - 1, 1)
        if isTimer(var1) then
          killTimer(var1)
        end
        var1 = setTimer(function(arg0)
          UI.DB[arg0].data.caretLine = math.max(UI.DB[arg0].data.caretLine - 1, 1)
          if uiMemoGetCaretIndex(arg0) ~= uiMemoGetCaretIndex(arg0) then
            triggerEvent("onClientUICaretPositionChange", arg0, uiMemoGetCaretIndex(arg0))
          end
        end, 150, 0, UI.FocusElement)
      elseif arg0 == "arrow_d" then
        UI.DB[UI.FocusElement].data.caretLine = math.min(UI.DB[UI.FocusElement].data.caretLine + 1, #(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }))
        if isTimer(var1) then
          killTimer(var1)
        end
        var1 = setTimer(function(arg0)
          UI.DB[arg0].data.caretLine = math.min(UI.DB[arg0].data.caretLine + 1, #var0)
          if uiMemoGetCaretIndex(arg0) ~= uiMemoGetCaretIndex(arg0) then
            triggerEvent("onClientUICaretPositionChange", arg0, uiMemoGetCaretIndex(arg0))
          end
        end, 150, 0, UI.FocusElement)
      end
      if uiMemoGetCaretIndex(UI.FocusElement) ~= uiMemoGetCaretIndex(UI.FocusElement) then
        triggerEvent("onClientUICaretPositionChange", UI.FocusElement, uiMemoGetCaretIndex(UI.FocusElement))
      end
    elseif isTimer(var1) then
      killTimer(var1)
    end
  end
end
bindKey("arrow_r", "both", moveCaret)
bindKey("arrow_l", "both", moveCaret)
bindKey("arrow_u", "both", moveCaret)
bindKey("arrow_d", "both", moveCaret)
function removeText(arg0, arg1)
  if UI.FocusElement and var0(UI.FocusElement) == "ui-edit" and not UI.DB[UI.FocusElement].data.readonly then
    if UI.DB[UI.FocusElement].text then
      if arg1 == "down" then
        if uiEditGetShadedText(UI.FocusElement) then
          UI.DB[UI.FocusElement].data.shading = {1, 1}
          uiSetText(UI.FocusElement, utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.shading[1] - 1) .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.shading[2], utfLen(UI.DB[UI.FocusElement].text)))
          uiEditSetCaretIndex(UI.FocusElement, UI.DB[UI.FocusElement].data.shading[1])
          triggerEvent("onClientUIChanged", UI.FocusElement)
        elseif arg0 == "backspace" then
          uiSetText(UI.FocusElement, utfSub(UI.DB[UI.FocusElement].text, 1, math.max(0, UI.DB[UI.FocusElement].data.caret - 2)) .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.caret, utfLen(UI.DB[UI.FocusElement].text)))
          uiEditSetCaretIndex(UI.FocusElement, math.max(1, UI.DB[UI.FocusElement].data.caret - 1))
          triggerEvent("onClientUIChanged", UI.FocusElement)
          if isTimer(var1) then
            killTimer(var1)
          end
          var2 = 0
          var1 = setTimer(function(arg0)
            var0 = var0 + 1
            if var0 >= 5 then
              uiSetText(arg0, utfSub(UI.DB[arg0].text, 1, math.max(0, UI.DB[arg0].data.caret - 2)) .. utfSub(UI.DB[arg0].text, UI.DB[arg0].data.caret, utfLen(UI.DB[arg0].text)))
              uiEditSetCaretIndex(arg0, math.max(1, UI.DB[arg0].data.caret - 1))
              triggerEvent("onClientUIChanged", arg0)
            end
          end, 80, 0, UI.FocusElement)
        elseif arg0 == "delete" then
          uiSetText(UI.FocusElement, utfSub(UI.DB[UI.FocusElement].text, 1, UI.DB[UI.FocusElement].data.caret - 1) .. utfSub(UI.DB[UI.FocusElement].text, UI.DB[UI.FocusElement].data.caret + 1, utfLen(UI.DB[UI.FocusElement].text)))
          triggerEvent("onClientUIChanged", UI.FocusElement)
          if isTimer(var1) then
            killTimer(var1)
          end
          var2 = 0
          var1 = setTimer(function(arg0)
            var0 = var0 + 1
            if var0 >= 5 then
              uiSetText(arg0, utfSub(UI.DB[arg0].text, 1, UI.DB[arg0].data.caret - 1) .. utfSub(UI.DB[arg0].text, UI.DB[arg0].data.caret + 1, utfLen(UI.DB[arg0].text)))
              triggerEvent("onClientUIChanged", arg0)
            end
          end, 80, 0, UI.FocusElement)
        end
      elseif isTimer(var1) then
        killTimer(var1)
      end
    end
  elseif UI.FocusElement and var0(UI.FocusElement) == "ui-memo" and not UI.DB[UI.FocusElement].data.readonly and UI.DB[UI.FocusElement].text then
    if arg1 == "down" then
      if replaceShadedText(UI.FocusElement, "") then
        triggerEvent("onClientUITextChange", UI.FocusElement)
        return
      end
      if arg0 == "backspace" then
        if #(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }) == 0 then
          return
        end
        if UI.DB[UI.FocusElement].data.caret == 1 and UI.DB[UI.FocusElement].data.caretLine ~= 1 then
          table.remove(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          }, UI.DB[UI.FocusElement].data.caretLine)
          UI.DB[UI.FocusElement].data.caret = utfLen((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine - 1]:gsub("" .. newLinePrefix, "")) + 1
          ;(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine - 1] = (UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine - 1]:gsub("" .. newLinePrefix, "") .. (UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, "")
          UI.DB[UI.FocusElement].data.caretLine = UI.DB[UI.FocusElement].data.caretLine - 1
        else
          (UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine] = utfSub((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""), 1, math.max(0, UI.DB[UI.FocusElement].data.caret - 2)) .. utfSub((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""), UI.DB[UI.FocusElement].data.caret, utfLen(((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""))))
          UI.DB[UI.FocusElement].data.caret = math.max(1, UI.DB[UI.FocusElement].data.caret - 1)
        end
        uiSetText(UI.FocusElement, table.concat(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }, "\n"):gsub("" .. newLinePrefix, ""))
        UI.DB[UI.FocusElement].data.showtext = table.concat(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }, "\n", UI.DB[UI.FocusElement].data.line_i, (math.min(#(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }), UI.DB[UI.FocusElement].data.line_i + math.floor(UI.DB[UI.FocusElement].dimensions.height / dxGetFontHeight(UI.DB[UI.FocusElement].font.size, UI.DB[UI.FocusElement].font.name)) + 1))):gsub("" .. newLinePrefix, "")
        if isTimer(var1) then
          killTimer(var1)
        end
        var2 = 0
        var1 = setTimer(function(arg0)
          var0 = var0 + 1
          if var0 >= 5 then
            if #(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
              UI.DB[arg0].text
            }) == 0 then
              return
            end
            if UI.DB[arg0].data.caret == 1 and UI.DB[arg0].data.caretLine ~= 1 then
              table.remove(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              }, UI.DB[arg0].data.caretLine)
              UI.DB[arg0].data.caret = utfLen((UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine - 1]:gsub("" .. newLinePrefix, "")) + 1
              ;(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine - 1] = (UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine - 1]:gsub("" .. newLinePrefix, "") .. (UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine]:gsub("" .. newLinePrefix, "")
              UI.DB[arg0].data.caretLine = UI.DB[arg0].data.caretLine - 1
            else
              (UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine] = utfSub((UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine]:gsub("" .. newLinePrefix, ""), 1, math.max(0, UI.DB[arg0].data.caret - 2)) .. utfSub((UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine]:gsub("" .. newLinePrefix, ""), UI.DB[arg0].data.caret, utfLen(((UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine]:gsub("" .. newLinePrefix, ""))))
              UI.DB[arg0].data.caret = math.max(1, UI.DB[arg0].data.caret - 1)
            end
            uiSetText(arg0, table.concat(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
              UI.DB[arg0].text
            }, "\n"):gsub("" .. newLinePrefix, ""))
            UI.DB[arg0].data.showtext = table.concat(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
              UI.DB[arg0].text
            }, "\n", UI.DB[arg0].data.line_i, (math.min(#(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
              UI.DB[arg0].text
            }), UI.DB[arg0].data.line_i + math.floor(UI.DB[arg0].dimensions.height / dxGetFontHeight(UI.DB[arg0].font.size, UI.DB[arg0].font.name)) + 1))):gsub("" .. newLinePrefix, "")
            if uiMemoGetCaretIndex(arg0) ~= uiMemoGetCaretIndex(arg0) then
              triggerEvent("onClientUICaretPositionChange", arg0, uiMemoGetCaretIndex(arg0))
            end
          end
        end, 80, 0, UI.FocusElement)
      elseif arg0 == "delete" then
        if #(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }) == 0 then
          return
        end
        if UI.DB[UI.FocusElement].data.caret == utfLen(((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""))) + 1 and UI.DB[UI.FocusElement].data.caretLine ~= #(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }) then
          (UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine] = (UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, "") .. (UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine + 1]:gsub("" .. newLinePrefix, "")
          table.remove(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          }, UI.DB[UI.FocusElement].data.caretLine + 1)
        else
          (UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine] = utfSub((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""), 1, UI.DB[UI.FocusElement].data.caret - 1) .. utfSub((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""), UI.DB[UI.FocusElement].data.caret + 1, utfLen(((UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
            UI.DB[UI.FocusElement].text
          })[UI.DB[UI.FocusElement].data.caretLine]:gsub("" .. newLinePrefix, ""))))
        end
        uiSetText(UI.FocusElement, table.concat(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }, "\n"):gsub("" .. newLinePrefix, ""))
        UI.DB[UI.FocusElement].data.showtext = table.concat(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }, "\n", UI.DB[UI.FocusElement].data.line_i, (math.min(#(UI.DB[UI.FocusElement].text:find("\n", 1, true) and split(UI.DB[UI.FocusElement].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
          UI.DB[UI.FocusElement].text
        }), UI.DB[UI.FocusElement].data.line_i + math.floor(UI.DB[UI.FocusElement].dimensions.height / dxGetFontHeight(UI.DB[UI.FocusElement].font.size, UI.DB[UI.FocusElement].font.name)) + 1))):gsub("" .. newLinePrefix, "")
        if isTimer(var1) then
          killTimer(var1)
        end
        var2 = 0
        var1 = setTimer(function(arg0)
          var0 = var0 + 1
          if var0 >= 5 then
            if #(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
              UI.DB[arg0].text
            }) == 0 then
              return
            end
            if UI.DB[arg0].data.caret == utfLen(((UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
              UI.DB[arg0].text
            })[UI.DB[arg0].data.caretLine]:gsub("" .. newLinePrefix, ""))) + 1 and UI.DB[arg0].data.caretLine ~= #(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
              UI.DB[arg0].text
            }) then
              (UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine] = (UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine]:gsub("" .. newLinePrefix, "") .. (UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine + 1]:gsub("" .. newLinePrefix, "")
              table.remove(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              }, UI.DB[arg0].data.caretLine + 1)
            else
              (UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine] = utfSub((UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine]:gsub("" .. newLinePrefix, ""), 1, UI.DB[arg0].data.caret - 1) .. utfSub((UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine]:gsub("" .. newLinePrefix, ""), UI.DB[arg0].data.caret + 1, utfLen(((UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
                UI.DB[arg0].text
              })[UI.DB[arg0].data.caretLine]:gsub("" .. newLinePrefix, ""))))
            end
            uiSetText(arg0, table.concat(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
              UI.DB[arg0].text
            }, "\n"):gsub("" .. newLinePrefix, ""))
            UI.DB[arg0].data.showtext = table.concat(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
              UI.DB[arg0].text
            }, "\n", UI.DB[arg0].data.line_i, (math.min(#(UI.DB[arg0].text:find("\n", 1, true) and split(UI.DB[arg0].text:gsub("\n", "\n" .. newLinePrefix), 10) or {
              UI.DB[arg0].text
            }), UI.DB[arg0].data.line_i + math.floor(UI.DB[arg0].dimensions.height / dxGetFontHeight(UI.DB[arg0].font.size, UI.DB[arg0].font.name)) + 1))):gsub("" .. newLinePrefix, "")
            if uiMemoGetCaretIndex(arg0) ~= uiMemoGetCaretIndex(arg0) then
              triggerEvent("onClientUICaretPositionChange", arg0, uiMemoGetCaretIndex(arg0))
            end
          end
        end, 80, 0, UI.FocusElement)
      end
      if uiMemoGetCaretIndex(UI.FocusElement) ~= uiMemoGetCaretIndex(UI.FocusElement) then
        triggerEvent("onClientUICaretPositionChange", UI.FocusElement, uiMemoGetCaretIndex(UI.FocusElement))
      end
    elseif isTimer(var1) then
      killTimer(var1)
    end
  end
end
bindKey("backspace", "both", removeText)
bindKey("delete", "both", removeText)
function acceptedEvent(arg0, arg1)
  if UI.FocusElement and var0(UI.FocusElement) == "ui-edit" and not UI.DB[UI.FocusElement].data.readonly and arg1 == "up" then
    triggerEvent("onClientUIAccepted", UI.FocusElement)
  end
end
bindKey("enter", "both", acceptedEvent)
bindKey("num_enter", "both", acceptedEvent)
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
    if arg0 == "Disabled" and arg1 == "True" and isUIElement(var0(source), "tabpanel") and source == UI.DB[var0(source)].data.selected_tab then
      uiSetSelectedTab(var0(source))
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
  if var0(source) == "ui-edit" or var0(source) == "ui-memo" then
    toggleControl("chatbox", true)
  end
end)
function cancelBindsOnTyping(arg0, arg1)
  if not UI.FocusElement then
    return
  end
  if arg1 and var0[string.lower(arg0)] and (var1(UI.FocusElement) == "ui-edit" or var1(UI.FocusElement) == "ui-memo") then
    cancelEvent()
  end
end
addEventHandler("onClientKey", root, cancelBindsOnTyping)
addEventHandler("onClientUITextChange", resourceRoot, function()
  if isUIElement(source, "label") then
  end
end)
function moveElement(arg0, arg1, arg2, arg3)
  if not isUIElement(UI.FocusElement, "window", "dialog") then
    removeEventHandler("onClientCursorMove", root, moveElement)
    return
  end
  uiSetPosition(UI.FocusElement, arg2 - (unpack(moveTemp) - unpack(moveTemp)), arg3 - (unpack(moveTemp) - unpack(moveTemp)))
end
function dragElement(arg0, arg1, arg2, arg3)
  UI.DB[UI.DraggedElement].dimensions.x = arg2 - (unpack(dragTemp) - unpack(dragTemp))
  UI.DB[UI.DraggedElement].dimensions.y = arg3 - (unpack(dragTemp) - unpack(dragTemp))
end
