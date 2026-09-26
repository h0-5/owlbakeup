-- Decompiled by Owl Decompiler
-- Version App : 1.0
-- discord.gg/owwl

function uiCreateButton(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
  if type(arg4) == "string" then
    arg4 = {en = arg4, ar = arg4}
  end
  if type(arg5) == "string" and theme.COLORS[arg5] then
  end
  UI.DB[createElement("ui-button")] = {
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
        value = theme.COLORS.black,
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
  addUIElement(createElement("ui-button"), arg6, sourceResource)
  return (createElement("ui-button"))
end
UI.getDrawFunction["ui-button"] = function(arg0)
  hoverUIElement(arg0, UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height)
  if UI.HoveredElement == arg0 then
    glowAlpha = anim(UI.DB[arg0].data.enterTick or 0, 200, 0, dxGetColor(UI.DB[arg0].colors[1]))
    if UI.DB[arg0].properties.HoverGlow.value then
      dxDrawImage(UI.DB[arg0].dimensions.x - 25, UI.DB[arg0].dimensions.y - 25, UI.DB[arg0].dimensions.width + 50, UI.DB[arg0].dimensions.height + 50, "images/glow.png", 0, 0, 0, tocolor(anim(UI.DB[arg0].data.enterTick or 0, 200, 0, dxGetColor(UI.DB[arg0].colors[1]))), UI.postGUI)
    end
  else
    glowAlpha = anim(UI.DB[arg0].data.leaveTick or 0, 200, dxGetColor(UI.DB[arg0].properties.HoverColor.value))
    if UI.DB[arg0].properties.HoverGlow.value then
      dxDrawImage(UI.DB[arg0].dimensions.x - 25, UI.DB[arg0].dimensions.y - 25, UI.DB[arg0].dimensions.width + 50, UI.DB[arg0].dimensions.height + 50, "images/glow.png", 0, 0, 0, tocolor(anim(UI.DB[arg0].data.leaveTick or 0, 200, dxGetColor(UI.DB[arg0].properties.HoverColor.value))), UI.postGUI)
    end
  end
  dxDrawRoundedRectangle(UI.DB[arg0].dimensions.x, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.width, UI.DB[arg0].dimensions.height, tocolor(anim(UI.DB[arg0].data.leaveTick or 0, 200, dxGetColor(UI.DB[arg0].properties.HoverColor.value))), 8 * SCALE_Y, UI.postGUI)
  dxDrawText(UI.DB[arg0].text[language], UI.DB[arg0].dimensions.x + 3, UI.DB[arg0].dimensions.y, UI.DB[arg0].dimensions.x + UI.DB[arg0].dimensions.width - 3, UI.DB[arg0].dimensions.y + UI.DB[arg0].dimensions.height, UI.HoveredElement == arg0 and UI.DB[arg0].properties.HoverTextColor.value or UI.DB[arg0].properties.TextColor.value, UI.DB[arg0].font.size, UI.DB[arg0].font.name, UI.DB[arg0].align.X, UI.DB[arg0].align.Y, true, false, UI.postGUI)
end
