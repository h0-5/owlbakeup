-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateButton(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
  local element = createElement("ui-button")
  if type(arg4) == "string" then
    arg4 = {en = arg4, ar = arg4}
  end
  if type(arg5) == "string" and theme.COLORS[arg5] then
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
      arg5 or theme.COLORS.black
    },
    data = {},
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
      },
      TextColor = {
        value = theme.COLORS.black,
        valueType = "number"
      },
      HoverTextColor = {
        value = false,
        valueType = "number"
      },
      HoverColor = {
        value = arg5 or theme.COLORS.black,
        valueType = "number"
      },
      HoverGlow = {
        value = false,
        valueType = "boolean",
        acceptedValues = {true, false}
      }
    }
  }
  addUIElement(element, arg6, sourceResource)
  return (element)
end
UI.getDrawFunction["ui-button"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  -- [Vortex fix] hover color blend restored (decompiler mangled the anim args)
  local bgColor = UI.DB[arg0].colors[1]
  if UI.HoveredElement == arg0 and UI.DB[arg0].properties.HoverColor and UI.DB[arg0].properties.HoverColor.value then
    bgColor = UI.DB[arg0].properties.HoverColor.value
  end
  -- [Vortex fix #14] pressed state rebuilt: on dark fills a -45 darken was
  -- invisible (9,12,17 -> near black), so presses looked dead. Now: deeper
  -- sink + 1px text shift + a white flash that fades 60 -> 0 over 150ms.
  local pressed = UI.DB[arg0].state == "clicked"
  if pressed then
    local br, bg_, bb, ba = dxGetColor(bgColor)
    bgColor = tocolor(math.max(0, br - 60), math.max(0, bg_ - 60), math.max(0, bb - 60), ba)
  end
  if UI.HoveredElement == arg0 then
    if UI.DB[arg0].properties.HoverGlow.value then
      dxDrawImage(UI.DB[arg0].dimensions.x - 25, UI.DB[arg0].dimensions.y - 25, UI.DB[arg0].dimensions.width + 50, UI.DB[arg0].dimensions.height + 50, "images/glow.png", 0, 0, 0, tocolor(dxGetColor(bgColor)), UI.postGUI)
    end
  end
  dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(dxGetColor(bgColor)), 8 * SCALE_Y, UI.postGUI)
  local pressTick = UI.DB[arg0].press_tick
  if pressTick then
    local pdt = getTickCount() - pressTick
    if pdt < 150 then
      dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(255, 255, 255, math.floor(60 * (1 - pdt / 150))), 8 * SCALE_Y, UI.postGUI)
    else
      UI.DB[arg0].press_tick = false
    end
  end
  local textY = UI.DB[arg0].dimensions.y + (pressed and 1 or 0)
  dxDrawText(UI.DB[arg0].text[language], UI.DB[arg0].dimensions.x + 3, textY, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 3, textY + UI.DB[arg0].dimensions.height, UI.HoveredElement == arg0 and UI.DB[arg0].properties.HoverTextColor.value or UI.DB[arg0].properties.TextColor.value, UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, false, UI.postGUI)
end
