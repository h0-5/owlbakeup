--[[
    UIKit theme - Vortex edition (blue / purple)
    Colours extracted from the official Vortex logo gradient:
        primary   #5E4CFC  rgb( 94,  76, 252)   Vortex blue
        secondary #9032FA  rgb(144,  50, 250)   Vortex purple
        accent    #46F2FD  rgb( 70, 242, 253)   Vortex cyan
    Dark surfaces keep the original 3/6/11 - 9/12/17 - 19/22/27 family
    so every restored mod keeps its original geometry and contrast.
]]

theme = {
    COLORS = {
        primary           = tocolor(94, 76, 252),
        secondary         = tocolor(144, 50, 250),
        accent            = tocolor(70, 242, 253),
        primary_dark      = tocolor(64, 50, 178),
        black             = tocolor(9, 12, 17),
        bg_default        = tocolor(3, 6, 11, 240),
        tabpanel_default  = {
            background   = tocolor(0, 0, 0, 0),
            tabs_bar     = tocolor(10, 10, 10),
            tab_selected = tocolor(44, 44, 46),
            tab_hovered  = tocolor(30, 30, 30),
        },
        scrollbar_default = tocolor(255, 255, 255, 60),
        text_default      = tocolor(255, 255, 255, 255),
        grey              = tocolor(255, 255, 255, 50),
        success           = tocolor(46, 213, 115),
        warning           = tocolor(255, 176, 32),
        danger            = tocolor(255, 65, 65)
    },
    FONTS = {
        ["ui-default"]    = { file = "fonts/Font2.ttf", size = 11.5 },
        ["default-large"] = { file = "fonts/Font2.ttf", size = 15 },
        ["PFDin"]         = { file = "fonts/PFDinDisplayPro-Regular.ttf", size = 14 },
        ["PFDin-Bold"]    = { file = "fonts/PFDinDisplayPro-Bold.ttf", size = 14 },
        ["PFDin-Big"]     = { file = "fonts/PFDinDisplayPro-Bold.ttf", size = 20 }
    }
}
